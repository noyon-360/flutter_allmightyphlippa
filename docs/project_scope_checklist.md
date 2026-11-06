# LabbyTV: Project Scope Checklist

Agreed scope from the original proposal (IPTV Player App, Fiverr, buyer: almightyflippa), checked against the code on **4 Nov 2026** (branch `feature/android-tv-support`).

**How to use:** when an item is finished and tested, change `[ ]` to `[x]`, add the date in *Notes*, and update the progress table.

Legend: `[x]` done · `[ ]` pending · ⚠️ partly done (see Notes)

**Where to check each item.** The project lives in three repos. Before ticking an item, check the code in the repo that owns it:

| Part | Local path | Remote |
|---|---|---|
| Mobile + Android TV app (Flutter) | `/Users/noyon/Documents/Flutter/flutter_allmightyphlippa-1` (this repo) | |
| Backend API (Node / Express 5 / MongoDB), live at `https://api.labbytv.com/api/v1` | `/Users/noyon/Documents/Backend/backend_almightyflippa` | `github.com/noyon-360/backend_almightyflippa` |
| Admin dashboard (Next.js 16 / React 19) | `/Users/noyon/Documents/Website/labbytv_dashboard` | `github.com/noyon-360/labbytv_dashboard` |

Items marked "backend" (sync, favourites, purchase verification, EPG, announcements, notifications) need a check in the backend repo too. Dashboard items are tracked in detail in the dashboard's own `.claude/CLAUDE.md` ("Build plan").

---

## Progress

| Area | Done | Total |
|---|---|---|
| Client-reported bugs | 0 | 3 |
| Playlist import & management | 2 | 7 |
| Live TV | 6 | 7 |
| VOD / movies / series | 6 | 7 |
| Playback | 3 | 4 |
| Casting & TV | 3 | 4 |
| Personalisation | 3 | 5 |
| Sync & cloud | 3 | 3 |
| Monetisation | 2 | 5 |
| Platforms & delivery | 3 | 6 |
| **Total** | **31** | **51** |

---

## 0. Client-reported bugs (4 Nov 2026)

- ⚠️ [ ] **Android Home button minimizes the app.** Pressing Home during playback should switch the video to PiP.
  - *Cause:* auto-PiP uses `floating`'s `OnLeavePiP`, which only works on Android 12+. On Android 8–11 it fails silently. There's also a race when switching channels: the old screen's `dispose()` disarms the new screen's PiP.
  - *Fix:* handle `onUserLeaveHint` / `setAutoEnterEnabled` in `MainActivity.kt`, and let only the screen that armed PiP disarm it (`pip_service.dart`).
  - *Status (4 Nov 2026):* **fixed in code, not committed.** `MainActivity.kt` now owns auto-PiP on the `labby/pip` channel: `setAutoEnterEnabled` on Android 12+, `onUserLeaveHint` → `enterPictureInPictureMode` on 8–11. `pip_service.dart` keeps a static owner, so only the screen that armed PiP can disarm it. The movie/series player now arms PiP when the video is ready, like Live TV (`video_play_screen.dart`). Verified: Home during an episode → PiP on the Android 17 emulator; `flutter analyze` and `flutter test` show nothing new. **Not verified:** Android 8–11 (no emulator image) and the channel-switch race.
  - *Waiting on the client:* video, device model, Android version. Tick once confirmed on their device or on an Android 8–11 device.
- ⚠️ [ ] **EPG from search opens the wrong category.** Picking a channel in search should open the guide on that channel's category.
  - *Cause:* `LiveTvController` is created lazily. Its `onInit()` starts the default load, and the category request gets dropped by `if (isLoading) return;`.
  - *Fix:* in `live_tv_controller.dart`, let an explicit `categoryId` supersede an in-flight load (using a request generation counter). Fall back to `categoryIds.first` when `category_id` is empty.
  - *Status (4 Nov 2026):* **fixed in code, not committed.** Search passes the channel's category to `LiveVideoPlayScreen(categoryId:)` (`movie_series_item_widget.dart`, with the `categoryIds.first` fallback). The player loads it after the first frame and scrolls to the channel (`live_video_play_screen.dart`). `live_tv_controller.dart` has a `_generation` counter: an explicit category supersedes an in-flight load, and stale responses are dropped. Verified: with the list already loaded, the guide shows the channel's category and marks it NOW PLAYING (phone emulator). **Not verified:** the lazy-init race itself (search → channel before the first Live TV load finishes). There's no unit test yet, because the controller needs GetX repo fakes.
- ⚠️ [ ] **Android TV: app closes when opening a movie or series.** The player page froze, then Android closed the app ("not responding").
  - *Cause:* the Download button's `Obx` in `video_play_screen.dart` returned early on `TvDevice.isTv` before reading any Rx value, so GetX threw "improper use of GetX" on TV only. In a debug run the debugger paused on that exception. Dart runs on the Android main thread, so the remote's key presses got no answer and Android raised an ANR (confirmed from the ANR trace: `DRT_Throw → Debugger::PauseException`). Also a 4px overflow in the Cast row on TV (`cast_section.dart`).
  - *Fix:* build the Download `Obx` only when not on TV; make the actor name `Flexible` so it shrinks instead of overflowing.
  - *Status (4 Nov 2026):* **fixed in code, not committed.** Verified on the Android TV emulator: opening a series shows the player page with no exceptions, the D-pad works and the app stays open. `flutter analyze` shows nothing new; `flutter test` 57 pass (the 1 failure is the old template `widget_test.dart` counter test, failing before this change). **Not verified:** a release build on a real TV device.

---

## 1. Core features

### 1.1 Playlist import & management

| | Feature | Notes |
|---|---|---|
| [x] | Import Xtream Codes (URL / username / password) | `features/playlist` |
| [ ] | Import M3U / M3U8 (URL or file) | Not started: no parser |
| [x] | Add, edit/rename, delete multiple playlists | `playlist_controller.dart` |
| [ ] | Reorder playlists | |
| [ ] | Colour / icon tagging of playlists | |
| [ ] | Move items between categories / playlists | |
| [ ] | Stremio add-on support (mentioned in overview) | Not started |

### 1.2 Live TV

| | Feature | Notes |
|---|---|---|
| [x] | Stream live channels | |
| [x] | Channels grouped by category | |
| [x] | Global channel search | Search covers movies, series and channels |
| [x] | EPG with timeline view | `features/epg`: ruler, day nav, channel rows |
| [x] | Touch EPG (drag / swipe) | `epg_timeline_controller.dart` |
| [x] | Tune in / set reminders from EPG | Reminders screen + local notifications |
| [ ] | Catch-up (replay missed shows) | `tv_archive` is read from the server but not used: no timeshift URL, no UI |

### 1.3 VOD / movies / series

| | Feature | Notes |
|---|---|---|
| [x] | Movies & series from playlist | |
| [x] | Filter by genre | Genre / category screens |
| [ ] | Filter by release year / language | |
| [x] | Global search across all content | |
| [x] | Favourites | Stored on the backend |
| [x] | Watch Later list | **Done (4 Nov 2026).** Backend deployed (`e9368d4`); tested on the Pixel 9 emulator (save, both tabs, "From: …" badge, find in this playlist, switch playlist and play, remove) and by the developer on device. Movies and series only (Live TV has EPG reminders). Saved per playlist, because stream ids differ between providers. Watch Later button on the movie/series page; Profile → Watch Later screen with "This playlist" / "All playlists" tabs. Items from another playlist are dimmed with a "From: …" badge and offer *Switch to that playlist and play*, *Find it in this playlist* (search by title) or *Remove*. The active playlist's id is now stored in `PlaylistData` (older installs are matched by credentials). The player shows a "couldn't load" state with Retry / Remove. Files: `features/watch_later/`, `playlist/services/active_playlist_service.dart`, `video_play_controller.dart`, `video_play_screen.dart`, `playlist_controller.dart`; tests in `test/watch_later_test.dart`. Backend: `model/watchLater.model.js`, `controller/watchLater.controller.js`, `route/watchLater.route.js`, mounted at `/watch-later`; items are deleted with their playlist and in `deleteAccount` (contract in `docs/backend_watch_later.md`). |
| [x] | Resume last-watched | Watch history + resume position |

---

## 2. Advanced features

### 2.1 Playback

| | Feature | Notes |
|---|---|---|
| [x] | Picture-in-Picture | `pip_service.dart`. Home-button auto-PiP on Android is handled in `MainActivity.kt` (see bug 0) |
| ⚠️ [ ] | Background playback (mobile) | iOS has the audio background mode, but only PiP keeps playing. No audio-only / lock-screen playback |
| [x] | Subtitles & multiple audio tracks | `track_picker_dialog.dart` |
| [x] | Smart buffering & auto-reconnect | mpv reconnect options, live retry, stream failure diagnosis |

### 2.2 Casting & display

| | Feature | Notes |
|---|---|---|
| [x] | Chromecast | Custom implementation in `core/services/cast` |
| [x] | AirPlay | `airplay_service.dart` |
| [x] | Android TV interface | Leanback launcher, TV nav rail, focus widgets. 4 Nov 2026: movie/series player has its own remote controls on TV (`features/video/widgets/tv_vod_controls.dart`), replacing media_kit's desktop controls, which only appear on mouse hover and so never showed on TV. Any key shows the bar (title, progress, time) and it hides after 5 s while playing. OK: fullscreen when embedded, play/pause in fullscreen. Left/Right ±10 s (hold to keep seeking), media keys work, Back exits fullscreen. Verified on the Android TV emulator; test `test/tv_vod_controls_test.dart`. The emulator shows a black picture (media_kit forces software rendering on emulators and the GL context fails); not yet checked on a real TV box. |
| [ ] | Apple TV (tvOS) app | Needs a separate native Swift app (Flutter can't target tvOS). Build prompt ready: `docs/tvos_app_prompt.md` |

### 2.3 Personalisation

| | Feature | Notes |
|---|---|---|
| [x] | Parental lock (PIN / Face ID / Touch ID) | 4 Nov 2026: done. Profile → Parental Lock: set / change / remove a 4-digit PIN, optional Face ID / fingerprint (`local_auth`), and lock Live / Movies / Series categories. Locked categories ask for the PIN (or biometrics) before opening and are hidden from "All", Home and Search. Entering the PIN opens only that category, and every unlock ends when the app goes to the background. Lock changes apply immediately (no restart): lists filter or reload through `ParentalLockService.changes`. 5 wrong PINs → 30 s wait. PIN stored as a salted SHA-256 hash in secure storage, locked IDs in Hive. Files: `core/services/parental_lock_service.dart`, `core/common/widgets/pin_pad_dialog.dart` (on-screen pad, D-pad + remote number keys), `features/parental/screens/parental_lock_screen.dart`. "Forgot PIN?" on the PIN pad asks for the account password (`POST /user/verify-password`, `core/common/widgets/password_confirm_dialog.dart`) and removes the PIN. ⚠️ Needs the backend endpoint deployed; until then it shows "Not available yet". Tests: `test/parental_lock_test.dart`. Not covered: Favourites, History, Watch Later and Continue Watching still show locked items. Locks are per area, not per playlist. Needs a device check for Face ID / fingerprint and the TV PIN pad. |
| [x] | Dark / light themes | 4 Nov 2026: done, free for all users. Visual pass in Light on phone + Android TV confirmed by developer. Profile → Appearance: Dark (default) / Light / System. `AppPalette` theme extension (`core/config/app_palette.dart`, read via `context.palette`), light + dark `ThemeData` in `app_theme.dart`, choice saved in Hive by `core/services/theme_service.dart`, picker in `features/profile/widgets/theme_picker_dialog.dart`. Players and the welcome screen stay dark on purpose. Dark looks exactly as before. Tests: `test/theme_test.dart`. Picking an option closes the dialog (needed on TV). |
| [x] | Rename playlists | |
| [ ] | Rename / reorder categories | |
| [ ] | Multi-language interface | Not started: all text hard-coded in English |

### 2.4 Sync & cloud backup

| | Feature | Notes |
|---|---|---|
| [x] | Sync playlists across devices | Stored on the backend per account |
| [x] | Sync favourites & watch progress | Backend watch-history API |
| [x] | Cloud user account (backup / restore) | Sign up, login, OTP, password reset |

### 2.5 Monetisation

| | Feature | Notes |
|---|---|---|
| [x] | Free + Premium model | `premium_service.dart` |
| [x] | In-app purchases / subscriptions (Play Store + App Store) | RevenueCat + backend purchase verification + subscription history |
| ⚠️ [ ] | Premium: ad-free playback | There are no ads at all. Ads not recommended yet (see section 5) |
| ⚠️ [ ] | Premium: unlimited EPG | EPG is premium-only. Free users get no EPG instead of a limited one |
| [ ] | Premium: theme customisation | Depends on the light theme / theme options |

---

## 3. Platforms & delivery

| | Item | Notes |
|---|---|---|
| [x] | Android app | v1.0.28+28 |
| [x] | iOS app | |
| [x] | Android TV (same AAB) | |
| [ ] | Apple TV app | See 2.2 |
| ⚠️ [ ] | Admin dashboard (React / Next.js) | Separate repo `labbytv_dashboard`. Per its `.claude/CLAUDE.md` (checked 4 Nov 2026): built — admin login + forgot/reset password, dashboard stats (computed client-side from `/admin/users`), user management (view, edit, delete, watch + subscription history), subscription overview, settings / profile. **Pending:** hosting decision and production CORS for the dashboard origin. Not deployed yet. Tick once it's hosted and the client can log in. Genre stats and editable plans need backend work (no endpoint / no plan model). |
| [ ] | Full source code + documentation handover | Covers all three repos (app, backend, dashboard) |

Backend (Node / Express 5 / MongoDB) is live at `https://api.labbytv.com`. Code: `/Users/noyon/Documents/Backend/backend_almightyflippa` (routes in `mainroute/index.js` → `route/*.route.js` → `controller/*.controller.js`, models in `model/`).

---

## 4. Nice-to-have (future phases, not in current scope)

- [ ] AI recommendation engine
- [ ] Voice commands (Google Assistant / Siri)
- [ ] Community / chat
- [ ] Regional content suggestions
- [ ] AI subtitles / translation

---

## 5. Proposed improvements (sent to the client, waiting for approval)

Not agreed yet. Move an item into scope once the client approves it.

- [ ] **Admin dashboard:** real watch time, user location & devices, reports (active users, top content, retention, revenue), weekly AI summary
- [ ] **Easier setup:** guided playlist setup with clear errors + reminder to users with no playlist (52% never add one)
- [ ] **Better live TV:** swipe to change channel, recent channels, now/next bar, one-tap favourites
- [ ] **Sports hub:** today's games, live badges, game reminders
- [ ] **More subscribers:** 7-day free trial, clearer upgrade prompts, more premium-only features
- Ads: **not recommended yet** (too few users)

---

## 6. Already built, outside the original scope

- Downloads (premium)
- Push notifications + notification inbox
- Announcements
- Actor / cast pages
- Watch history screen

---

## Suggested order for pending work

1. Bug fixes from section 0
2. M3U / M3U8 import
3. Catch-up
4. Parental lock
5. Watch Later + year / language filters
6. Playlist reordering + colour tags, rename / reorder categories
7. Light theme + multi-language
8. Background audio playback
9. Apple TV app
10. Admin dashboard: host the built dashboard (in scope); the section 5 extras only if the client approves them






```
**IPTV Catch-Up Feature**

Catch-Up allows users to go back and watch programs that already aired on a live TV channel.

**Example:**

Let's say ESPN has the following schedule:

- 6:00 PM: SportsCenter
- 7:00 PM: NBA Basketball
- 9:30 PM: SportsCenter
- 10:30 PM: NBA Highlights

It's currently 11:00 PM.

A user opens ESPN's EPG (TV Guide), scrolls backward to the NBA game that aired at 7:00 PM, and clicks it.

Instead of switching to the current live broadcast, the app plays the NBA game from 7:00 PM.

**How It Should Work:**

1. Open a live TV channel that supports Catch-Up.
2. Open the channel's EPG.
3. Scroll backward to previous programs.
4. Select a program that already aired.
5. Choose "Watch Catch-Up" or "Play."
6. The program starts playing from its original beginning.
7. Users can pause, rewind, and fast-forward if supported.

**Important Details:**

- Catch-Up is only available on channels that support it.
- The IPTV provider must supply the archived content.
- Some providers offer 24 hours, 3 days, or 7 days of Catch-Up.
- The EPG should visually identify programs that support Catch-Up.
- Programs outside the available archive period shouldn't display a working Catch-Up option.

**The Goal:**

Make Catch-Up feel like selecting an older program from a TV guide and watching it on demand, without having to search for a separate recording.
```