import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../tv/repositories/live_tv_repo.dart';

class LiveVideoPlayController extends GetxController {
  final _liveTvRepo = Get.find<LiveTvRepo>();

  late final Player player;
  late final VideoController videoController;

  final isVideoInitialized = false.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    player = Player();
    videoController = VideoController(player);
  }

  @override
  void onClose() {
    player.dispose();
    super.onClose();
  }

  Future<void> initializeLiveVideo({required int streamId}) async {
    isVideoInitialized.value = false;
    isLoading.value = true;

    try {
      final result = await _liveTvRepo.getSingleLiveTV(streamId: streamId);

      result.fold(
        (fail) {
          debugPrint('Error fetching live TV URL: ${fail.message}');
          Get.snackbar('Error', 'Failed to fetch live stream URL');
        },
        (success) async {
          final playUrl = success.data.playUrl;
          debugPrint('Live TV Play URL: $playUrl');
          if (playUrl.isNotEmpty) {
            await player.open(Media(playUrl));
            isVideoInitialized.value = true;
          } else {
            Get.snackbar('Error', 'Stream URL is empty');
          }
        },
      );
    } catch (e) {
      debugPrint('Error initializing live video: $e');
      Get.snackbar('Error', 'An unexpected error occurred');
    } finally {
      isLoading.value = false;
    }
  }
}
