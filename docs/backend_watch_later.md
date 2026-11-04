# Backend change: Watch Later

**Status (4 Nov 2026): implemented in `backend_almightyflippa` (`main`, not committed or deployed yet).** This doc is the reference for the contract. The code in the backend repo is the source of truth; it also checks for malformed ids (400 instead of a 500 CastError) and deletes Watch Later items in `deleteAccount`.

**Why a new collection and not a flag on `WatchHistory`:** `POST /watch-history/update` always sets `lastWatchedAt` and creates a history row, so saving an unwatched title would show it in Watch History and Continue Watching. History rows also don't know which playlist they belong to. Watch Later items are per playlist, because stream ids differ between providers.

## 1. Model: `model/watchLater.model.js` (new)

```js
import mongoose, { Schema } from "mongoose";

const watchLaterSchema = new Schema(
  {
    user: { type: Schema.Types.ObjectId, ref: "User", required: true },
    playlist: { type: Schema.Types.ObjectId, ref: "Playlist", required: true },
    // Movies and series only. Live TV uses EPG reminders instead.
    videoType: { type: String, enum: ["movie", "series"], required: true },
    // Xtream stream_id (movie) or series_id (series), as a string.
    videoId: { type: String, required: true },
    title: { type: String, default: "" },
    thumbnail: { type: String, default: "" },
  },
  { timestamps: true },
);

// One entry per title per playlist. The same movie can be saved on two
// playlists, because ids are only meaningful within one provider.
watchLaterSchema.index(
  { user: 1, playlist: 1, videoType: 1, videoId: 1 },
  { unique: true },
);
watchLaterSchema.index({ user: 1, createdAt: -1 });

export const WatchLater = mongoose.model("WatchLater", watchLaterSchema);
```

## 2. Controller: `controller/watchLater.controller.js` (new)

```js
import httpStatus from "http-status";
import AppError from "../errors/AppError.js";
import { Playlist } from "../model/palylist.model.js";
import { WatchLater } from "../model/watchLater.model.js";
import catchAsync from "../utils/catchAsync.js";
import sendResponse from "../utils/sendResponse.js";

const VIDEO_TYPES = ["movie", "series"];

// GET /watch-later?playlistId=&page=&limit=
// Without playlistId: every playlist's items. Each item carries
// playlist { _id, name } so the app can say where it's from.
export const getWatchLater = catchAsync(async (req, res) => {
  const page = Math.max(parseInt(req.query.page) || 1, 1);
  const limit = Math.min(Math.max(parseInt(req.query.limit) || 20, 1), 100);
  const filter = { user: req.user._id };
  if (req.query.playlistId) filter.playlist = req.query.playlistId;

  const [items, total] = await Promise.all([
    WatchLater.find(filter)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .populate("playlist", "name"),
    WatchLater.countDocuments(filter),
  ]);

  sendResponse(res, {
    statusCode: httpStatus.OK,
    success: true,
    message: "Watch later retrieved successfully",
    data: {
      items,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(total / limit),
        totalItems: total,
      },
    },
  });
});

// POST /watch-later  { playlistId, videoType, videoId, title, thumbnail }
// Upsert, so a double tap or a retry doesn't fail on the unique index.
export const addWatchLater = catchAsync(async (req, res) => {
  const { playlistId, videoType, videoId, title, thumbnail } = req.body;
  if (!playlistId || !videoId || !VIDEO_TYPES.includes(videoType)) {
    throw new AppError(httpStatus.BAD_REQUEST, "playlistId, videoId and a valid videoType are required");
  }

  const owns = await Playlist.exists({ _id: playlistId, user: req.user._id });
  if (!owns) {
    throw new AppError(httpStatus.NOT_FOUND, "Playlist not found or unauthorized");
  }

  const key = { user: req.user._id, playlist: playlistId, videoType, videoId: String(videoId) };
  const item = await WatchLater.findOneAndUpdate(
    key,
    { $set: { title: title || "", thumbnail: thumbnail || "" } },
    { new: true, upsert: true, setDefaultsOnInsert: true },
  ).populate("playlist", "name");

  sendResponse(res, {
    statusCode: httpStatus.OK,
    success: true,
    message: "Added to watch later",
    data: item,
  });
});

// GET /watch-later/status?playlistId=&videoType=&videoId=
// For the player's bookmark button.
export const getWatchLaterStatus = catchAsync(async (req, res) => {
  const { playlistId, videoType, videoId } = req.query;
  if (!playlistId || !videoType || !videoId) {
    throw new AppError(httpStatus.BAD_REQUEST, "playlistId, videoType and videoId are required");
  }
  const item = await WatchLater.findOne({
    user: req.user._id,
    playlist: playlistId,
    videoType,
    videoId: String(videoId),
  }).select("_id");

  sendResponse(res, {
    statusCode: httpStatus.OK,
    success: true,
    message: "Watch later status",
    data: { isSaved: !!item, id: item?._id ?? null },
  });
});

// DELETE /watch-later/:id
export const removeWatchLater = catchAsync(async (req, res) => {
  const item = await WatchLater.findOneAndDelete({ _id: req.params.id, user: req.user._id });
  if (!item) {
    throw new AppError(httpStatus.NOT_FOUND, "Item not found");
  }
  sendResponse(res, {
    statusCode: httpStatus.OK,
    success: true,
    message: "Removed from watch later",
    data: null,
  });
});
```

(Use the same `http-status` import as `epg.controller.js`.)

## 3. Route: `route/watchLater.route.js` (new)

```js
import express from "express";
import { protect } from "../middleware/auth.middleware.js";
import {
  getWatchLater,
  addWatchLater,
  getWatchLaterStatus,
  removeWatchLater,
} from "../controller/watchLater.controller.js";

const router = express.Router();
router.use(protect);

router.get("/", getWatchLater);
router.post("/", addWatchLater);
router.get("/status", getWatchLaterStatus); // before "/:id" routes
router.delete("/:id", removeWatchLater);

export default router;
```

Not premium-gated: the scope doesn't list Watch Later as a premium feature.

## 4. Mount it: `mainroute/index.js`

```js
import watchLaterRoute from "../route/watchLater.route.js";
// ...
router.use("/watch-later", watchLaterRoute);
```

## 5. Clean up on playlist delete: `controller/playlist.controller.js` → `deletePlaylist`

After the playlist is found and deleted:

```js
import { WatchLater } from "../model/watchLater.model.js";
// ...
await WatchLater.deleteMany({ user: userId, playlist: playlistId });
```

`updatePlaylist` keeps the same `_id`, so saved items survive a credentials change.

## Contract summary

| Method | Path | Body / query | `data` |
|---|---|---|---|
| GET | `/watch-later` | `?playlistId&page&limit` | `{ items: [Item], pagination }` |
| POST | `/watch-later` | `{ playlistId, videoType, videoId, title, thumbnail }` | `Item` |
| GET | `/watch-later/status` | `?playlistId&videoType&videoId` | `{ isSaved, id }` |
| DELETE | `/watch-later/:id` | | `null` |

`Item` = `{ _id, user, playlist: { _id, name } | null, videoType, videoId, title, thumbnail, createdAt, updatedAt }`. `playlist` is `null` only if a playlist was deleted before step 5 was deployed.
