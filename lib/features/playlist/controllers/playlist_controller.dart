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

  @override
  void onInit() {
    super.onInit();
    fetchPlaylists();
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

  void updateControllers() {
    Get.put(MovieController()).onInit();
    Get.put(SeriesController()).onInit();
    Get.put(LiveTvController()).onInit();
    Get.put(ProfileController()).onInit();
  }

  Future<void> fetchPlaylists() async {
    isFetchingList.value = true;

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

          updateControllers();

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

    updateControllers();

    Get.offAll(() => BottomNavScreen());
  }
}
