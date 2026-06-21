import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../profile/controller/profile_controller.dart';
import '../../tv/repositories/live_tv_repo.dart';

class LiveVideoPlayController extends GetxController {
  final _liveTvRepo = Get.find<LiveTvRepo>();
  final _profileCtrl = Get.find<ProfileController>();

  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;

  final isVideoInitialized = false.obs;
  final isLoading = false.obs;

  /// The URL of the stream currently being played (used for casting).
  String? _currentPlayUrl;
  String? get currentPlayUrl => _currentPlayUrl;

  bool get isSubscribed {
    final user = _profileCtrl.userProfile.value;
    return user?.subscriptionStatus == 'active' || user?.plan == 'premium';
  }

  @override
  void onClose() {
    videoPlayerController?.dispose();
    chewieController?.dispose();
    super.onClose();
  }

  Future<void> initializeLiveVideo({required int streamId}) async {
    isVideoInitialized.value = false;
    isLoading.value = true;

    // Dispose old controllers if they exist
    await videoPlayerController?.dispose();
    chewieController?.dispose();
    videoPlayerController = null;
    chewieController = null;

    try {
      final result = await _liveTvRepo.getSingleLiveTV(streamId: streamId);

      await result.fold(
        (fail) async {
          debugPrint('Error fetching live TV URL: ${fail.message}');
        },
        (success) async {
          String playUrl = success.data.playUrl;
          
          if (!isSubscribed && playUrl.isNotEmpty) {
            // Append quality parameter for non-subscribed users
            // Note: This parameter name might depend on the IPTV server
            final separator = playUrl.contains('?') ? '&' : '?';
            playUrl = '$playUrl${separator}quality=low';
            debugPrint('Non-subscribed user: requesting low quality stream');
          }

          debugPrint('Live TV Play URL: $playUrl');
          _currentPlayUrl = playUrl;

          if (playUrl.isNotEmpty) {
            videoPlayerController = VideoPlayerController.networkUrl(
              Uri.parse(playUrl),
              // Uri.parse(
              //   "http://proxpanel.pro/live/tes83747/tes736836/748395.m3u8",
              // ),
            );

            await videoPlayerController!.initialize();

            chewieController = ChewieController(
              videoPlayerController: videoPlayerController!,
              autoPlay: true,
              isLive: true,
              looping: false,
              aspectRatio: 16 / 9,
              errorBuilder: (context, errorMessage) {
                return Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            );

            isVideoInitialized.value = true;
          } else {
            Get.snackbar('Error', 'Stream URL is empty');
          }
        },
      );
    } catch (e) {
      debugPrint('Error initializing live video: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
