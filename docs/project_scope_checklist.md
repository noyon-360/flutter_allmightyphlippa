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
| Client-reported bugs | 0 | 2 |
| Playlist import & management | 2 | 7 |
| Live TV | 6 | 7 |
| VOD / movies / series | 5 | 7 |
| Playback | 3 | 4 |
| Casting & TV | 3 | 4 |
| Personalisation | 2 | 5 |
| Sync & cloud | 3 | 3 |
| Monetisation | 2 | 5 |
| Platforms & delivery | 3 | 6 |
| **Total** | **29** | **50** |

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
| [ ] | Watch Later list | Not started |
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
| [x] | Android TV interface | Leanback launcher, TV nav rail, focus widgets |
| [ ] | Apple TV (tvOS) app | Needs a separate native Swift app (Flutter can't target tvOS). Build prompt ready: `docs/tvos_app_prompt.md` |

### 2.3 Personalisation

| | Feature | Notes |
|---|---|---|
| [ ] | Parental lock (PIN / Face ID / Touch ID) | Not started: no `local_auth` |
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
