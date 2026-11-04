# LabbyTV: IPTV Player App

Flutter IPTV player (Android, iOS, Android TV) for the client **almightyflippa** (US). Users sign up, add their own Xtream Codes playlist, and watch Live TV (with EPG), movies and series. Package name `flutter_almightyflippa`, app name **LABBY**.

## Project goal

**Finish the agreed scope of work.** The checklist in [docs/project_scope_checklist.md](../docs/project_scope_checklist.md) is the single source of truth for what is done and what is still pending.

### How to work through the scope

1. **Pick the next item.** Bugs in section 0 come first, then follow "Suggested order for pending work" at the bottom of the checklist, unless the user names a different item.
2. **Read the relevant code before planning.** The checklist notes say where each feature lives and what's missing.
3. **Implement it** following the conventions below. Keep each change to one checklist item.
4. **Verify it:** run `flutter analyze` (no new errors or warnings), run `flutter test`, and add a unit test for any pure logic (parsers, models, controller state). Say plainly what you could not test, for example device-only behaviour like PiP or casting.
5. **Update the checklist.** Tick `[x]` only after the code is in the repo and verified, add the date and a short note (key files), and update the progress table counts. Never tick an item based on someone saying it's done; check the code first.
6. **Report back** to the user with what changed, how it was verified, and what is next.

Scope rules:
- Section 4 (nice-to-have) and section 5 (proposed improvements) are **not in scope** until the user says the client approved them. Then move the item into scope in the checklist.
- New client bug reports go into section 0 with cause, fix and status.
- Only commit or push when the user asks. Work on a feature branch, never directly on `main`.

## Related repos

The project is three repos. This one is the app. Read the other two to check API shapes and whether a checklist item is really done:

| Repo | Path | What to look at |
|---|---|---|
| Backend (Node / Express 5 / MongoDB, ESM) | `/Users/noyon/Documents/Backend/backend_almightyflippa` | `server.js` mounts `mainroute/index.js` at `/api/v1`. Routes in `route/<name>.route.js`, logic in `controller/<name>.controller.js`, schemas in `model/`, Xtream proxy cache in `utils/xtreamCache.js`, store verification in `utils/apple.service.js` / `google.service.js`, push in `utils/fcm.js`, cron in `utils/scheduler.js`. Responses are `{ success, message, data }` (watch history uses `{ status, message, data }`). |
| Admin dashboard (Next.js 16, React 19, TanStack Query) | `/Users/noyon/Documents/Website/labbytv_dashboard` | Its own `.claude/CLAUDE.md` has the build plan, the admin API it uses, "Backend additions" and "Known backend issues". API calls in `src/api/`, screens in `src/features/`. |

Rules for the other repos:
- **Read only.** Never edit, commit, or run write commands (`npm install`, scripts, `node server.js`) in the backend or dashboard from this project. If app work needs a backend or dashboard change, stop and tell the user what to change, where and why.
- **Never read or print** the backend's `.env` or `secret/` folder.
- When an endpoint in `core/constants/api_constants.dart` is in doubt, confirm it against `mainroute/index.js` + the matching `route/*.route.js` file before changing app code.
- The backend and dashboard are on `main` and in production; `git -C <path> log` is fine for checking what changed.

## Commands

```bash
flutter pub get
flutter analyze
flutter test                        # unit tests in test/
flutter test integration_test       # needs a device or emulator
flutter run                         # add -d <device>
flutter build appbundle             # Android phone + Android TV (one AAB)
flutter build ipa
```

Version is in `pubspec.yaml` (`version: x.y.z+build`). Android and iOS use different build numbers; the iOS line is commented out next to it.

## Architecture

```
lib/
  core/
    api/          ApiClient (Dio), NetworkResult, error handling
    constants/    ApiConstants (all endpoints), colours, assets, cache keys
    di/           setup_core / setup_services / setup_repository / setup_controllers
    services/     cast, airplay, pip, premium, revenuecat, notifications, storage, watch history
    common/       shared widgets (incl. TV focus widgets), shimmer, base models
    config/       app_theme.dart (dark theme only right now)
  features/<feature>/
    controllers/  GetX controllers
    repositories/ (or repo/) abstract repo + *_impl.dart
    models/       fromJson/toJson models
    screens/  widgets/  services/
```

- **State and DI: GetX.** Controllers and repos are registered lazily in `core/di/` with `Get.getOrPutLazy(..., fenix: true)` and fetched with `Get.find`. A lazily created controller runs `onInit()` when first found, so a load you trigger right after `Get.find` can race with the controller's own initial load. `LiveTvController.getLiveTvList(categoryId:)` handles this with a `_generation` counter (an explicit category supersedes the in-flight load), so use the same pattern if another controller needs it.
- **Networking:** repos call `ApiClient().get/post<T>(endpoint: ApiConstants.<group>.<name>, data:, fromJsonT:)` and return `NetworkResult<T>` (`Future<Either<NetworkFailure, NetworkSuccess<T>>>`, via dartz). Controllers handle results with `result.fold(fail, success)`. Add new endpoints to `core/constants/api_constants.dart`.
- **Backend:** `https://api.labbytv.com/api/v1` (Node/Express/MongoDB, separate repo, see "Related repos"). The app doesn't call the IPTV server directly: it sends the playlist's `serverUrl/username/password` to the backend (`ServerRequestModel.fromStorage`), and the backend proxies Xtream. Do not change backend contracts from the app side; if a feature needs a new endpoint, tell the user it needs backend work.
- **Storage:** Hive (cache), `flutter_secure_storage` (tokens, credentials), `AuthStorageService` for the active playlist.
- **Video:** `media_kit` (mpv) for playback; `video_player` + `chewie` are still in deps. Track picker for subtitles and audio. Live is `LiveVideoPlayScreen` + `LiveVideoPlayController`; VOD is `VideoPlayScreen` + `VideoPlayController`.
- **Premium:** check with `PremiumService.to.isPremium.value` (reactive, use inside `Obx`). Purchases go through RevenueCat (`revenuecat_service.dart`) with backend verification.
- **TV:** detect with `core/utils/tv_device.dart` (MainActivity `labby/device` channel). Every new interactive widget must work with a D-pad: wrap it in `TvFocusWrapper` and use `tv_layout` / `tv_key_scroll` / `tv_shortcuts`. The TV layout uses `tv_nav_rail.dart`.
- **Native code:** `android/app/src/main/kotlin/com/example/flutter_almightyflippa/MainActivity.kt` and `ios/Runner/AppDelegate.swift` (iOS PiP channel `com.labbytv/pip`).

## Conventions

- Match the existing style: one feature per folder, repo interface + impl, controller per screen or area.
- Comments explain **why** (platform quirks, races, Xtream oddities), like the existing ones. Don't add comments that repeat the code.
- Use `AppColors` and the theme, not hard-coded colours. All UI text is English and hard-coded for now. If multi-language gets done, move strings out then.
- Only gate features to Premium where the scope says so.
- Use `DPrint` (flutx_core) for logging.

## Known pitfalls

- **Xtream only.** M3U/M3U8 import does not exist yet (it's a pending scope item). Xtream catalog order is not stable across pages, so de-duplicate on load-more (see the movie, series and live controllers).
- **Xtream EPG** titles and descriptions are base64-encoded (`EpgProgramModel`). EPG can only be fetched one channel at a time, so use the caches in `features/epg/services/`.
- **Player screens are replaced with `Get.off` when switching channels.** The old screen's `dispose()` runs after the new screen's `initState()`. That's why controllers use a unique `tag`. Anything shared and global (PiP arming, cast callbacks) must not be torn down by the old screen.
- **Android PiP:** `floating`'s `OnLeavePiP` only works on Android 12+, so auto-PiP (Home / Recents during playback) is handled natively in `MainActivity.kt` on the `labby/pip` channel: `setAutoEnterEnabled` on 12+, `onUserLeaveHint` on 8–11. Arm and disarm only through `PiPService.armAutoEnter()` / `disarmAutoEnter()`. Only the PiPService that armed it can disarm it, so an old player screen's `dispose()` can't cancel the new screen's PiP. `floating` is still used for availability, status and manual PiP. iOS enters PiP from `didChangeAppLifecycleState`.
- **Apple TV:** Flutter cannot target tvOS. The Apple TV app has to be a separate native Swift project using the same backend. The build brief is in `docs/tvos_app_prompt.md`.
- `tv_archive` / `tv_archive_duration` on live channels are already parsed. That's the starting point for catch-up.
- Never commit `key.properties`, keystores or other secrets.

## Client communication

The client is non-technical. Messages to them should be short and friendly (WhatsApp style, a few emojis), with no code terms. Each one should say what was fixed or added and what's next, and ask only for what's actually needed (video, device model, Android version).
