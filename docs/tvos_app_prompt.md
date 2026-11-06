# Prompt: Build the LABBY TV app for Apple TV (tvOS)

Copy everything below the line into a new Claude Code session (or give it to a developer).

---

## Task

Create a **native Apple TV (tvOS) app** for **LABBY TV**, an IPTV streaming app (live TV with EPG guide, movies, series). An Android phone/TV app and an iPhone app already exist in Flutter, but **Flutter cannot target tvOS**, so this must be a separate native Swift project that talks to the **same backend**.

Work in phases. **Stop after Phase 1** and report to me before continuing.

## Tech requirements

- Swift 6, **SwiftUI**, tvOS 17+ deployment target, Xcode project (no Flutter, no third-party UI frameworks).
- Video: **AVKit / AVPlayer** (`AVPlayerViewController` for full-screen playback — it gives Siri Remote controls, scrubbing, subtitles and audio-track menus for free).
- Networking: `URLSession` + `async/await` + `Codable`.
- Secure storage: **Keychain** for tokens and IPTV credentials (never `UserDefaults`).
- In-app purchases: **RevenueCat** `purchases-ios` via Swift Package Manager.
- Bundle ID: `com.almightyflippa.labbytv` (same as the iPhone app, so **Universal Purchase** lets iPhone subscribers use Apple TV without paying again). Confirm with me before changing it.
- Must run in the **Apple TV simulator** (Xcode → Apple TV 4K) for every phase.
- Focus engine: every screen must be fully usable with the Siri Remote — visible focus effect on every focusable item, sensible initial focus, Menu/Back button always goes back one level, never a dead end.

## Backend API (already live, do not change it)

Base URL: `https://api.labbytv.com/api/v1`

Every response is wrapped: `{ "success": bool, "message": string, "data": ... }` (some endpoints use `"status"` instead of `"success"`). Authenticated calls send `Authorization: Bearer <accessToken>`. All calls below are **POST with JSON body** unless noted.

### Auth
| Endpoint | Body | Returns (`data`) |
|---|---|---|
| `/auth/login` | `{ email, password, deviceId }` | `{ accessToken, refreshToken, role, _id, user }` |
| `/auth/register` | name, email, password (check the Flutter `RegisterRequestModel`) | user |
| `/auth/refresh-token` | `{ refreshToken }` | `{ accessToken, refreshToken }` |
| `/auth/forget` | `{ email }` | emails a 6-digit OTP |
| `/auth/reset-password` | `{ email, otp, password }` (otp as **string**) | — |
| `/user/profile` | GET | user profile |

On HTTP 401: call `/auth/refresh-token` once, retry the request; if refresh fails, log out to the login screen.

### Playlists (the user's IPTV provider accounts)
| Endpoint | Notes |
|---|---|
| `/playlist/get-playlist` | GET. Each playlist has `url` (serverUrl), `username`, `password`. The user picks one; store it in Keychain — every content call below needs it. |

### Content (all take the selected playlist's credentials)
Common body: `{ serverUrl, username, password, type, search?, limit, page }` where `type` is `channels` (live), `movies` or `series`.

| Endpoint | Purpose |
|---|---|
| `/server/connect-tv` | Paged list of channels / movies / series (`page`, `limit` e.g. 10–50). Also used for search via `search`. |
| `/category` and `/category/{id}` | Categories and items in a category (check `GenreRepo` in the Flutter app for the exact body). |
| `/server/get-play-url` | Body: `{ serverUrl, username, password, stream_type, stream_id }` (`stream_type`: `live` / `movie` / `series`). Returns `{ data: { info }, playUrl }` — **`playUrl` is what AVPlayer plays.** |
| `/epg/schedule` | Body: `{ serverUrl, username, password, streamId, from, to }` with `from`/`to` as **Unix seconds (UTC)**. Returns a list of programmes (title, start, end, description). |
| `/watch-history/update`, `/watch-history/history`, `/watch-history/favorites` | Continue-watching and favourites (Phase 3). |

### Subscription
- RevenueCat entitlement: **`LABBY TV Pro`**. Products: `month_subscription`, `premium_quarterly`, `premium_t_yearly`.
- Call `Purchases.logIn(<user _id>)` after login so the entitlement follows the account across iPhone and Apple TV.
- Backend status: `/payment/my-subscription` (GET). After an Apple purchase the app calls `/payment/verify-apple-purchase` — copy the exact body from the Flutter `SubscriptionRepo`.
- Ask me for the **RevenueCat Apple API key**; never hard-code a placeholder that looks real.

**Reference implementation:** the Flutter app at `<path to flutter_allmightyphlippa>` — read `lib/core/constants/api_constants.dart`, the `*_repo_impl.dart` files and the models in `lib/features/*/models/` for exact field names before writing each `Codable` model. Don't guess field names.

## Screens (TV-style layout, not a phone layout)

Use a **left sidebar / top tab navigation** (SwiftUI `TabView` with `.sidebarAdaptable` or top tabs), large text readable from 3 metres, 16:9 landscape only.

1. **Login** — email + password (tvOS keyboard), Forgot Password (email → OTP + new password), Sign Up.
2. **Playlist picker** — shown when the user has more than one playlist; remember the choice.
3. **Home** — Continue Watching, Popular Movies, Popular Series rows (horizontal shelves, poster cards with focus lift effect).
4. **Live TV** — category chips row + channel grid; selecting a channel plays it full-screen. **Channel up/down** on the Siri Remote (swipe up/down while playing) switches to the next/previous channel in the current category.
5. **TV Guide (EPG)** — grid: channels down, time across, current time marker; focusing a programme shows details; OK on a live programme plays the channel.
6. **Movies / Series** — category chips + poster grid; detail page (poster, description, cast, Play); series show seasons + episodes.
7. **Search** — one search field, results for channels, movies, series.
8. **Profile** — account info, subscription status, playlists, logout, privacy policy / terms (scrollable text).
9. **Paywall** — the three plans from RevenueCat, focusable plan cards, Restore Purchases. Premium-only features (EPG guide, no watermark) must check the `LABBY TV Pro` entitlement.

## Phases

**Phase 1 — Proof of concept (STOP after this):**
- Create the Xcode tvOS project, folder structure (`App/`, `Core/Networking`, `Core/Storage`, `Features/...`), API client with token refresh, Keychain store.
- Login screen → fetch playlists → pick one → load the first page of live channels → play one channel full-screen in AVPlayer.
- **Critical check:** test that the provider's stream URLs actually play in AVPlayer. AVPlayer supports HLS (`.m3u8`) and MP4, **not** raw MPEG-TS or `.mkv`. Log the `playUrl` formats you see for live, movie and series, report which ones play and which fail. If many fail, propose options (ask the backend for HLS URLs, or use a VLC-based player such as `TVVLCKit`) — do not pick one without asking me.
- Report: what works in the simulator, screenshots, the stream-format findings, and open questions.

**Phase 2 — Core app:** Home, Live TV with categories and channel switching, Movies, Series with episodes, full-screen player with resume position, Search.

**Phase 3 — Premium & account:** EPG guide grid, RevenueCat paywall + entitlement gating, watch history / favourites, Profile, Forgot Password, Sign Up.

**Phase 4 — Release prep:** app icon and Top Shelf image (tvOS needs layered/parallax app icons: 400×240 and 1280×768, Top Shelf 1920×720 and 2320×720), App Store screenshots at 1920×1080, crash-free run through every screen with the Siri Remote only, privacy manifest (`PrivacyInfo.xcprivacy`).

## Rules

- Never log or commit the user's password, tokens or IPTV credentials (the Flutter debug logs print them — don't copy that).
- Don't modify the backend or the Flutter project.
- Keep secrets (RevenueCat key) out of git; use an `.xcconfig` that is git-ignored.
- After each phase: build in Xcode, run in the Apple TV simulator, and tell me exactly what was and wasn't tested.
