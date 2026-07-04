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
  final errorMessage = Rxn<String>();

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
    errorMessage.value = null;
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
          errorMessage.value = 'Could not reach the server.\nPlease check your connection and try again.';
        },
        (success) async {
          String playUrl = success.data.playUrl;

          if (!isSubscribed && playUrl.isNotEmpty) {
            final separator = playUrl.contains('?') ? '&' : '?';
            playUrl = '$playUrl${separator}quality=low';
            debugPrint('Non-subscribed user: requesting low quality stream');
          }

          debugPrint('Live TV Play URL: $playUrl');
          _currentPlayUrl = playUrl;

          if (playUrl.isEmpty) {
            errorMessage.value = 'Stream URL is unavailable for this channel.';
            return;
          }

          videoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse(playUrl),
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
        },
      );
    } catch (e) {
      debugPrint('Error initializing live video: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('socketexception') || msg.contains('failed host lookup') || msg.contains('network')) {
        errorMessage.value = 'No internet connection.\nPlease check your network and try again.';
      } else if (msg.contains('404') || msg.contains('not found')) {
        errorMessage.value = 'Channel stream not found.\nThe channel may be temporarily unavailable.';
      } else if (msg.contains('521') || msg.contains('522') || msg.contains('520') || msg.contains('connection refused')) {
        errorMessage.value = 'The stream server is currently down.\nPlease try again later.';
      } else {
        errorMessage.value = 'Failed to load stream.\nThe server may be temporarily unavailable.';
      }
    } finally {
      isLoading.value = false;
    }
  }
}
