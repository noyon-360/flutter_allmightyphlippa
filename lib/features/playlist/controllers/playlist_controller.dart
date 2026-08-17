import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/services/auth_storage_service.dart';
import 'package:flutter_almightyflippa/features/bottom_nav/screens/bottom_nav_screen.dart';
import 'package:flutter_almightyflippa/features/movie/controllers/movie_controller.dart';
import 'package:flutter_almightyflippa/features/profile/controller/profile_controller.dart';
import 'package:flutter_almightyflippa/features/series/controllers/series_controller.dart';
import 'package:flutter_almightyflippa/features/tv/controllers/live_tv_controller.dart';
import 'package:get/get.dart';
import '../models/playlist_data.dart';
import '../models/playlist_model.dart';
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

  /// Fires off the initial movies/series/live TV/profile fetches for a
  /// newly added or switched playlist, and shows a blocking status dialog
  /// (Updating -> Completed/Failed) so the user isn't dropped onto a
  /// silently-loading Home screen with no feedback on whether setup
  /// actually worked.
  Future<void> updateControllers() async {
    syncStatus.value = PlaylistSyncStatus.updating;
    Get.dialog(const PlaylistSyncDialog(), barrierDismissible: false);

    final movieCtrl = Get.put(MovieController());
    final seriesCtrl = Get.put(SeriesController());
    final liveTvCtrl = Get.put(LiveTvController());
    movieCtrl.onInit();
    seriesCtrl.onInit();
    liveTvCtrl.onInit();
    Get.put(ProfileController()).onInit();

    const timeout = Duration(seconds: 20);
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final stillLoading = movieCtrl.isLoading.value ||
          seriesCtrl.isLoading.value ||
          liveTvCtrl.isLoading.value;
      if (!stillLoading) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final hasAnyData = movieCtrl.movies.isNotEmpty ||
        seriesCtrl.series.isNotEmpty ||
        liveTvCtrl.liveTvList.isNotEmpty;

    syncStatus.value =
        hasAnyData ? PlaylistSyncStatus.completed : PlaylistSyncStatus.failed;

    // Let the user see the final state briefly before dismissing.
    await Future.delayed(const Duration(milliseconds: 700));
    if (Get.isDialogOpen ?? false) Get.back();
    syncStatus.value = PlaylistSyncStatus.idle;
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
