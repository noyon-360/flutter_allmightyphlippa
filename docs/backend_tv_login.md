# Backend change: Sign in on a TV with your phone

**Status (6 Nov 2026): implemented in both repos, not committed or deployed.** The backend code is the source of truth; sections 1–3 below are the original proposal and differ in small ways:

- Controller is in its own file `controller/tvLogin.controller.js`; model `model/tvLogin.model.js`; routes added to `route/auth.route.js`.
- Rate limits use a small in-memory limiter (`utils/rateLimit.js`), no new npm package: `/tv/code` 10 per IP per 10 min, `/tv/poll` 60 per IP per min, `/tv/approve` 5 *failed* tries per user per 10 min. Per process, so with several server instances each one counts on its own.
- Per-device sessions (section 4a) are done: `utils/sessionTokens.js`, used by login, refresh, logout, change / reset password and `tvPoll`. Refresh tokens get a random `jti`, are stored as SHA-256 in `user.refreshTokens` (`select: false`, max 10 per user). Tokens issued before the deploy (old `user.refreshToken` field) are accepted once and moved to the list, so nobody is logged out by the deploy. The app now sends `X-Device-ID` on the refresh call too (`api_client.dart`).
- Logout ends only that device's session. Change password ends every other device's session; reset password ends all of them.
- Free users (4b): unchanged rule, the newest device (the TV) becomes the active one. Still waiting on the client's decision.
- Verified against a throwaway local MongoDB with dummy secrets (34 checks: full approve / deny / expire flow, single use, guessing limit, phone stays signed in after the TV signs in, legacy migration, password change, logout). Not run against the real server or database.

Until this is deployed, the TV login screen shows "Sign in with your phone is not available yet." next to the normal email form, so the app can ship first.

Typing an email and password with a TV remote is slow. So the TV shows a QR code and a short code, and a phone that is already signed in approves it. This is the OAuth "device authorization" pattern (RFC 8628), the same idea Netflix and YouTube use.

```
TV                          Backend                         Phone (signed in)
POST /auth/tv/code  ───────▶ creates TvLogin (pending)
◀── deviceCode, userCode
shows QR + userCode
POST /auth/tv/poll (every 5 s) ─▶ "pending"
                                         ◀────── POST /auth/tv/approve {userCode}  (protect)
                             marks approved, links user
POST /auth/tv/poll  ───────▶ "approved" + tokens (once), deletes TvLogin
```

## Security rules (please keep all of them)

1. **The TV never gets a password.** Tokens are only issued after a signed-in phone approves.
2. **Two codes.** `userCode` (8 chars, shown on screen) is only used to *approve*. `deviceCode` (32 random bytes, never shown) is the only thing that can *collect the tokens*. Someone who photographs the TV screen can't get the tokens.
3. **Only hashes in the database.** Store SHA-256 of both codes, never the raw values.
4. **Short lived and single use.** Expires after 10 min (Mongo TTL index). Tokens are handed out once, then the document is deleted.
5. **Rate limits.** `/tv/approve` is the code-guessing target: at most 5 failed approvals per user per 10 min (or per IP with `express-rate-limit`). `/tv/code` at most ~10 per IP per 10 min.
6. **No 401 from `/tv/code` or `/tv/poll`.** The app treats any 401 as "session expired" and tries to refresh / log out. Use 404 for an unknown or expired `deviceCode`.
7. **Code alphabet must match the app** (`TvLoginCodeFormat.alphabet` in `lib/features/auth/models/tv_login_models.dart`): `BCDFGHJKMNPQRTVWXZ2346789`, length 8. No vowels (no words) and no look-alikes (0/O, 1/I/L, 5/S). The app rejects codes with other characters before calling the server.

## API contract

All responses use the usual `{ success, message, data }` shape.

### `POST /api/v1/auth/tv/code` (no auth)

Body: `{ "deviceId": "<X-Device-ID of the TV>", "deviceName": "Android TV" }`

`200` →
```json
{ "deviceCode": "<64 hex chars>", "userCode": "K7PQ4XMZ", "expiresIn": 600, "interval": 5 }
```
`expiresIn` and `interval` are seconds. The app never polls faster than every 2 s.

### `POST /api/v1/auth/tv/poll` (no auth)

Body: `{ "deviceCode": "..." }`

`200` with `data.status`:
- `"pending"`: not approved yet.
- `"denied"`: the phone said no. The TV shows a note and gets a new code.
- `"expired"`: the TV gets a new code.
- `"approved"`: same fields as `/auth/login`, plus `status`:
  ```json
  { "status": "approved", "accessToken": "...", "refreshToken": "...", "role": "user", "_id": "...", "user": { ... } }
  ```

`404` = unknown / already used / expired `deviceCode`. The TV gets a new code. Any other error (5xx, timeout) and the TV keeps polling.

### `POST /api/v1/auth/tv/approve` (`protect`)

Body: `{ "userCode": "K7PQ4XMZ", "approve": true }` (`approve: false` = deny)

`200` → `{ "deviceName": "Android TV" }`
`404` = wrong or expired code, `429` = too many tries. The app shows a message for each.

## 1. Model: `model/tvLogin.model.js` (new)

```js
import mongoose, { Schema } from "mongoose";

const tvLoginSchema = new Schema(
  {
    deviceCodeHash: { type: String, required: true, unique: true },
    userCodeHash: { type: String, required: true, unique: true },
    deviceId: { type: String, default: "" },   // the TV's X-Device-ID
    deviceName: { type: String, default: "TV" },
    status: { type: String, enum: ["pending", "approved", "denied"], default: "pending" },
    user: { type: Schema.Types.ObjectId, ref: "User" },
    expiresAt: { type: Date, required: true },
  },
  { timestamps: true },
);

// Mongo deletes expired requests on its own (checked about once a minute,
// so the controllers also compare expiresAt themselves).
tvLoginSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

export const TvLogin = mongoose.model("TvLogin", tvLoginSchema);
```

## 2. Controller: add to `controller/auth.controller.js`

```js
import crypto from "crypto";
import { TvLogin } from "../model/tvLogin.model.js";

const TV_CODE_ALPHABET = "BCDFGHJKMNPQRTVWXZ2346789";
const TV_CODE_TTL_S = 600;
const TV_POLL_INTERVAL_S = 5;
const sha256 = (s) => crypto.createHash("sha256").update(s).digest("hex");

const randomUserCode = () => {
  let code = "";
  for (let i = 0; i < 8; i++) code += TV_CODE_ALPHABET[crypto.randomInt(TV_CODE_ALPHABET.length)];
  return code;
};

const normalizeUserCode = (c) => String(c || "").toUpperCase().replace(/[\s-]/g, "");

export const tvCreateCode = catchAsync(async (req, res) => {
  const { deviceId = "", deviceName = "TV" } = req.body;
  const deviceCode = crypto.randomBytes(32).toString("hex");

  // userCode is unique among live requests; retry on the rare collision.
  let userCode;
  for (let i = 0; i < 5; i++) {
    userCode = randomUserCode();
    if (!(await TvLogin.exists({ userCodeHash: sha256(userCode) }))) break;
  }

  await TvLogin.create({
    deviceCodeHash: sha256(deviceCode),
    userCodeHash: sha256(userCode),
    deviceId: String(deviceId).slice(0, 128),
    deviceName: String(deviceName).slice(0, 64),
    expiresAt: new Date(Date.now() + TV_CODE_TTL_S * 1000),
  });

  sendResponse(res, {
    statusCode: httpStatus.OK,
    success: true,
    message: "TV sign-in code created",
    data: { deviceCode, userCode, expiresIn: TV_CODE_TTL_S, interval: TV_POLL_INTERVAL_S },
  });
});

export const tvApprove = catchAsync(async (req, res) => {
  const userCode = normalizeUserCode(req.body.userCode);
  const approve = req.body.approve !== false;

  const request = await TvLogin.findOne({
    userCodeHash: sha256(userCode),
    status: "pending",
    expiresAt: { $gt: new Date() },
  });
  if (!request) {
    throw new AppError(httpStatus.NOT_FOUND, "This code has expired or is wrong");
  }

  request.status = approve ? "approved" : "denied";
  request.user = req.user._id;
  await request.save();

  sendResponse(res, {
    statusCode: httpStatus.OK,
    success: true,
    message: approve ? "TV approved" : "TV sign-in declined",
    data: { deviceName: request.deviceName },
  });
});

export const tvPoll = catchAsync(async (req, res) => {
  const { deviceCode } = req.body;
  if (!deviceCode) throw new AppError(httpStatus.BAD_REQUEST, "deviceCode is required");

  const hash = sha256(String(deviceCode));
  const request = await TvLogin.findOne({ deviceCodeHash: hash });
  if (!request) throw new AppError(httpStatus.NOT_FOUND, "Unknown or used code");

  const reply = (data) =>
    sendResponse(res, { statusCode: httpStatus.OK, success: true, message: data.status, data });

  if (request.expiresAt < new Date()) {
    await request.deleteOne();
    return reply({ status: "expired" });
  }
  if (request.status === "pending") return reply({ status: "pending" });
  if (request.status === "denied") {
    await request.deleteOne();
    return reply({ status: "denied" });
  }

  // Approved: hand the tokens out exactly once. findOneAndDelete is atomic,
  // so two polls racing can't both get them.
  const claimed = await TvLogin.findOneAndDelete({ deviceCodeHash: hash, status: "approved" });
  if (!claimed) throw new AppError(httpStatus.NOT_FOUND, "Unknown or used code");

  const user = await User.findById(claimed.user);
  if (!user) throw new AppError(httpStatus.NOT_FOUND, "Unknown or used code");

  const jwtPayload = { _id: user._id, email: user.email, role: user.role };
  const accessToken = createToken(jwtPayload, process.env.JWT_ACCESS_SECRET, process.env.JWT_ACCESS_EXPIRES_IN);
  const refreshToken = createToken(jwtPayload, process.env.JWT_REFRESH_SECRET, process.env.JWT_REFRESH_EXPIRES_IN);

  // See section 4: store this per device so the phone stays signed in.
  user.refreshToken = refreshToken;
  if (user.plan !== "premium" && claimed.deviceId) user.activeDeviceId = claimed.deviceId;
  await user.save();

  reply({ status: "approved", accessToken, refreshToken, role: user.role, _id: user._id, user });
});
```

## 3. Routes: `route/auth.route.js`

```js
router.post("/tv/code", tvCreateCode);
router.post("/tv/poll", tvPoll);
router.post("/tv/approve", protect, tvApprove);
```

Rate limiting, with `express-rate-limit` (`npm i express-rate-limit`):

```js
import rateLimit from "express-rate-limit";
const tvCodeLimit = rateLimit({ windowMs: 10 * 60 * 1000, limit: 10 });
const tvApproveLimit = rateLimit({ windowMs: 10 * 60 * 1000, limit: 5, skipSuccessfulRequests: true });

router.post("/tv/code", tvCodeLimit, tvCreateCode);
router.post("/tv/approve", protect, tvApproveLimit, tvApprove);
```

Behind a proxy (nginx, Render, etc.) also set `app.set("trust proxy", 1)` in `server.js`, or every user shares one IP.

## 4. Two existing issues this feature will hit

**a) One refresh token per user.** `user.refreshToken` holds a single token, and `/auth/refresh-token` rejects any other. So when the TV signs in, the phone's refresh token stops working and the phone is logged out at its next token refresh. (This already happens today with password logins on two devices.) Suggested fix: keep a list.

```js
// model/user.model.js
refreshTokens: [{ token: String, deviceId: String, updatedAt: { type: Date, default: Date.now } }],
```

- On login and in `tvPoll`: drop any entry with the same `deviceId`, push the new one, keep the newest ~10.
- In `refreshToken`: find the entry whose `token` matches (also accept the old `user.refreshToken` field during rollout), replace that entry's token.
- In `logout`: remove the entry for the request's `X-Device-ID` (or clear all).
- In `changePassword` / `resetPassword`: clear all, so a stolen session dies with the old password.

**b) Free plan = one device.** `activeDeviceId` is set to the newest device. For a free user, approving the TV moves the session to the TV, and the phone gets "Your account is now active on another device" on its next request. That matches how password login works today. If the client wants phone + TV together on Free, skip the `activeDeviceId` line in `tvPoll`. **Needs a decision from the client.**

## App side (done)

- TV: `lib/features/auth/widgets/tv_qr_login_panel.dart` (QR + code, next to the email form in `login_screen.dart` on TV only), `controller/tv_qr_login_controller.dart` (request, poll, renew on expiry / deny / 404, then the same post-login steps as `LoginController`).
- Phone: Profile → **Sign in on a TV** → `screens/tv_login_approve_screen.dart` (in-app QR scanner via `mobile_scanner`, or type the code) → confirm dialog → `controller/tv_login_approve_controller.dart`.
- QR payload: `labbytv://tv-login?code=K7PQ4XMZ`. Only the in-app scanner reads it for now. Opening the app from the phone's own camera needs a deep link (`app_links` + Android intent filter + iOS URL scheme). That's a possible follow-up.
- Tests: `test/tv_login_test.dart`.
