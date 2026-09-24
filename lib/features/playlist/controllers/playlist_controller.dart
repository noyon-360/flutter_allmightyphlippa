import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/services/auth_storage_service.dart';
import 'package:flutter_almightyflippa/features/bottom_nav/screens/bottom_nav_screen.dart';
import 'package:flutter_almightyflippa/features/genre/controllers/genre_controller.dart';
import 'package:flutter_almightyflippa/features/movie/controllers/movie_controller.dart';
import 'package:flutter_almightyflippa/features/profile/controller/profile_controller.dart';
import 'package:flutter_almightyflippa/features/series/controllers/series_controller.dart';
import 'package:flutter_almightyflippa/features/tv/controllers/live_tv_controller.dart';
import 'package:get/get.dart';
import '../../epg/services/epg_timeline_cache.dart';
import '../../epg/services/live_tv_now_playing_cache.dart';
import '../models/playlist_data.dart';
import '../models/playlist_model.dart';
import '../models/playlist_sync_step.dart';
import '../models/server_request_model.dart';
import '../repositories/playlist_repo.dart';
import '../widgets/playlist_sync_dialog.dart';

enum PlaylistSyncStatus { idle, updating, completed, failed }

class PlaylistController extends GetxController {
  final _playlistRepo = Get.find<PlaylistRepo>();
  final AuthStorageService _authStorageService = AuthStorageService();

  // TextControllers
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final urlController = TextEditingController();

  // FocusNodes
  final nameFocus = FocusNode();
  final usernameFocus = FocusNode();
  final passwordFocus = FocusNode();
  final urlFocus = FocusNode();

  // Form Key
  final playlistFormKey = GlobalKey<FormState>();

  // States
  final RxString playlistErrorMessage = "".obs;
  final RxList<PlaylistModel> playlists = <PlaylistModel>[].obs;
  final RxBool isFetchingList = false.obs;
  final Rxn<PlaylistData> activePlaylistData = Rxn<PlaylistData>();
  final syncStatus = PlaylistSyncStatus.idle.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPlaylists();
  }

  Future<void> _loadActivePlaylistData() async {
    activePlaylistData.value = await _authStorageService.getPlaylistData();
  }

  /// Whether [playlist] is the credentials currently in use by the app,
  /// so the playlist list can show which one is active.
  bool isActivePlaylist(PlaylistModel playlist) {
    final active = activePlaylistData.value;
    if (active == null || active.isEmpty) return false;
    return playlist.url == active.url &&
        playlist.userName == active.username &&
        playlist.password == active.password;
  }

  @override
  void onClose() {
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    urlController.dispose();
    nameFocus.dispose();
    usernameFocus.dispose();
    passwordFocus.dispose();
    urlFocus.dispose();
    super.onClose();
  }

  /// The steps of the update currently (or last) running, for the sync dialog.
  final syncSteps = <SyncStep>[].obs;

  /// Set while the dialog is waiting on the user after a failed update:
  /// completes with true to retry the failed steps, false to carry on anyway.
  Completer<bool>? _syncDecision;

  void retrySync() => _syncDecision?.complete(true);
  void continueAfterFailedSync() => _syncDecision?.complete(false);

  /// Loads (or reloads) everything for the active playlist — categories and
  /// first pages of Live TV, Movies and Series — behind a blocking dialog that
  /// shows which step is running and which finished or failed, so the user can
  /// tell whether an update is working, stuck, or done. Used after adding or
  /// selecting a playlist and for the manual "Update Playlist" action.
  ///
  /// The steps run in parallel (they're independent requests), so the dialog
  /// lists them all and headlines the one currently running. If any fail, the
  /// user can retry just those or continue with what loaded.
  Future<void> updateControllers() async {
    final movieCtrl = Get.put(MovieController());
    final seriesCtrl = Get.put(SeriesController());
    final liveTvCtrl = Get.put(LiveTvController());
    final movieGenres = Get.put(GenreController(), tag: 'movies');
    final seriesGenres = Get.put(GenreController(), tag: 'series');
    final liveGenres = Get.put(GenreController(), tag: 'channels');

    // A category picked on the previous playlist doesn't exist on this one.
    movieCtrl.selectedCategoryId.value = '';
    seriesCtrl.selectedCategoryId.value = '';
    liveTvCtrl.selectedCategoryId.value = '';

    final jobs = <(SyncStep, Future<bool> Function())>[
      (
        SyncStep(
          label: 'Live TV categories',
          activeText: 'Getting Live TV Categories…',
        ),
        () => _loadGenres(liveGenres, ServerType.live),
      ),
      (
        SyncStep(
          label: 'Live TV channels',
          activeText: 'Getting Live TV Channels…',
        ),
        () async {
          await _waitWhile(() => liveTvCtrl.isLoading.value);
          await liveTvCtrl.getLiveTvList();
          return liveTvCtrl.errorMessage.value == null;
        },
      ),
      (
        SyncStep(
          label: 'Movie categories',
          activeText: 'Getting Movie Categories…',
        ),
        () => _loadGenres(movieGenres, ServerType.movies),
      ),
      (
        SyncStep(label: 'Movies', activeText: 'Getting Movies…'),
        () async {
          await _waitWhile(() => movieCtrl.isLoading.value);
          await movieCtrl.getMovies();
          return movieCtrl.errorMessage.value == null;
        },
      ),
      (
        SyncStep(
          label: 'Series categories',
          activeText: 'Getting Series Categories…',
        ),
        () => _loadGenres(seriesGenres, ServerType.series),
      ),
      (
        SyncStep(label: 'Series', activeText: 'Getting Series…'),
        () async {
          await _waitWhile(() => seriesCtrl.isLoading.value);
          await seriesCtrl.getSeries();
          return seriesCtrl.errorMessage.value == null;
        },
      ),
      (
        // Guide data is fetched per channel as rows appear, so "updating" it
        // means discarding what's cached so the next view loads fresh data.
        SyncStep(label: 'TV guide', activeText: 'Updating EPG…'),
        () async {
          Get.find<EpgTimelineCache>().clear();
          Get.find<LiveTvNowPlayingCache>().clear();
          return true;
        },
      ),
    ];

    syncSteps.assignAll([for (final (step, _) in jobs) step]);
    syncStatus.value = PlaylistSyncStatus.updating;
    Get.dialog(const PlaylistSyncDialog(), barrierDismissible: false);

    // Not a step: the account profile just refreshes in the background.
    Get.put(ProfileController()).onInit();

    while (true) {
      syncStatus.value = PlaylistSyncStatus.updating;
      await Future.wait([
        for (final (step, run) in jobs)
          if (step.state.value != SyncStepState.done) _runStep(step, run),
      ]);

      final anyFailed =
          syncSteps.any((s) => s.state.value == SyncStepState.failed);
      if (!anyFailed) {
        syncStatus.value = PlaylistSyncStatus.completed;
        break;
      }

      syncStatus.value = PlaylistSyncStatus.failed;
      _syncDecision = Completer<bool>();
      final retry = await _syncDecision!.future;
      _syncDecision = null;
      if (!retry) break;
    }

    // Let the user see the final state briefly before dismissing.
    if (syncStatus.value == PlaylistSyncStatus.completed) {
      await Future.delayed(const Duration(milliseconds: 700));
    }
    if (Get.isDialogOpen ?? false) Get.back();
    syncStatus.value = PlaylistSyncStatus.idle;
  }

  Future<void> _runStep(SyncStep step, Future<bool> Function() run) async {
    step.state.value = SyncStepState.running;
    try {
      final ok = await run().timeout(const Duration(seconds: 60));
      step.state.value = ok ? SyncStepState.done : SyncStepState.failed;
    } catch (_) {
      step.state.value = SyncStepState.failed;
    }
  }

  Future<bool> _loadGenres(GenreController ctrl, ServerType type) async {
    await _waitWhile(() => ctrl.isLoading.value);
    // Drop the previous playlist's categories so a failed load can't pass for
    // a successful one.
    ctrl.genres.clear();
    await ctrl.getGenres(type: type);
    return ctrl.errorMessage.value == null;
  }

  /// The content controllers ignore a load requested while one is already in
  /// flight; wait that one out so our own call actually runs.
  Future<void> _waitWhile(bool Function() busy) async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (busy() && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // ─── Edit ────────────────────────────────────────────────────────────────

  /// The playlist being edited by the add/edit screen, or null when adding.
  PlaylistModel? editingPlaylist;

  /// Fills the form with [playlist] and remembers it as the one being edited.
  void startEditing(PlaylistModel playlist) {
    editingPlaylist = playlist;
    playlistErrorMessage.value = "";
    nameController.text = playlist.name ?? '';
    usernameController.text = playlist.userName ?? '';
    passwordController.text = playlist.password ?? '';
    urlController.text = playlist.url ?? '';
  }

  void clearForm() {
    editingPlaylist = null;
    nameController.clear();
    usernameController.clear();
    passwordController.clear();
    urlController.clear();
    playlistErrorMessage.value = "";
  }

  /// Saves the edited name / URL / username / password onto the *same*
  /// playlist rather than deleting and re-adding it. If it's the playlist in
  /// use, the app switches to the new credentials and reloads its content.
  Future<void> updatePlaylist() async {
    final original = editingPlaylist;
    if (original?.id == null) return;
    if (!(playlistFormKey.currentState?.validate() ?? false)) return;

    playlistErrorMessage.value = "";
    final updated = original!.copyWith(
      name: nameController.text.trim(),
      userName: usernameController.text.trim(),
      password: passwordController.text.trim(),
      url: urlController.text.trim(),
    );

    // Decided against the credentials as they are now, before they change.
    final wasActive = isActivePlaylist(original);

    final result = await _playlistRepo.updatePlaylist(updated);
    final failure = result.fold((fail) => fail, (_) => null);
    if (failure != null) {
      playlistErrorMessage.value = failure.message;
      return;
    }

    if (wasActive) {
      await _authStorageService.savePlaylistData(
        PlaylistData(
          url: updated.url ?? '',
          username: updated.userName ?? '',
          password: updated.password ?? '',
        ),
      );
    }
    await fetchPlaylists();
    clearForm();
    Get.back();

    if (wasActive) await updateControllers();
  }

  Future<void> fetchPlaylists() async {
    isFetchingList.value = true;
    await _loadActivePlaylistData();

    // First, try to load from local storage
    final localPlaylists = await _authStorageService.getPlaylists();
    if (localPlaylists.isNotEmpty) {
      playlists.value = localPlaylists
          .map((e) => PlaylistModel.fromJson(e))
          .toList();
    }

    // Then, fetch from network
    final result = await _playlistRepo.getPlaylists();

    isFetchingList.value = false;

    result.fold(
      (fail) {
        // If local is empty, show error
        if (playlists.isEmpty) {
          playlistErrorMessage.value = fail.message;
        }
      },
      (success) async {
        playlists.value = success.data;
        // Sync to local storage
        await _authStorageService.storePlaylists(
          success.data.map((e) => e.toJson()).toList(),
        );
      },
    );
  }

  Future<void> addPlaylist() async {
    if (playlistFormKey.currentState?.validate() ?? false) {
      playlistErrorMessage.value = "";

      final playlist = PlaylistModel(
        name: nameController.text.trim(),
        userName: usernameController.text.trim(),
        password: passwordController.text.trim(),
        url: urlController.text.trim(),
      );

      final result = await _playlistRepo.addPlaylist(playlist);

      result.fold(
        (fail) {
          playlistErrorMessage.value = fail.message;
        },
        (success) async {
          final playlistData = PlaylistData(
            url: urlController.text.trim(),
            username: usernameController.text.trim(),
            password: passwordController.text.trim(),
          );
          await _authStorageService.savePlaylistData(playlistData);

          // Clear inputs
          nameController.clear();
          usernameController.clear();
          passwordController.clear();
          urlController.clear();

          await updateControllers();

          Get.to(() => BottomNavScreen());
        },
      );
    }
  }

  Future<void> addPlaylistBackList() async {
    if (playlistFormKey.currentState?.validate() ?? false) {
      playlistErrorMessage.value = "";

      final playlist = PlaylistModel(
        name: nameController.text.trim(),
        userName: usernameController.text.trim(),
        password: passwordController.text.trim(),
        url: urlController.text.trim(),
      );

      final result = await _playlistRepo.addPlaylist(playlist);

      result.fold(
        (fail) {
          playlistErrorMessage.value = fail.message;
        },
        (success) async {
          // final playlistData = PlaylistData(
          //   url: urlController.text.trim(),
          //   username: usernameController.text.trim(),
          //   password: passwordController.text.trim(),
          // );
          // await _authStorageService.savePlaylistData(playlistData);

          // // Clear inputs
          // nameController.clear();
          // usernameController.clear();
          // passwordController.clear();
          // urlController.clear();

          // updateControllers();

          Get.back();
        },
      );
    }
  }

  Future<void> deletePlaylist(String id) async {
    final result = await _playlistRepo.deletePlaylist(id);

    result.fold(
      (fail) {
        Get.snackbar(
          "Error",
          fail.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
      (success) async {
        await fetchPlaylists();
      },
    );
  }

  Future<void> selectPlaylist(PlaylistModel playlist) async {
    // Store selected playlist details for request model usage using the centralized model
    final playlistData = PlaylistData(
      url: playlist.url ?? '',
      username: playlist.userName ?? '',
      password: playlist.password ?? '',
    );
    await _authStorageService.savePlaylistData(playlistData);
    await _loadActivePlaylistData();

    await updateControllers();

    Get.offAll(() => BottomNavScreen());
  }
}
