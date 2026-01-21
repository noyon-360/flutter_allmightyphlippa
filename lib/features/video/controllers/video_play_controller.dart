import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../movie/controllers/movie_controller.dart';

class VideoPlayController extends GetxController {
  final movieCtrl = Get.find<MovieController>();

  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;
  final isVideoInitialized = false.obs;

  @override
  void onClose() {
    _disposeVideoControllers();
    super.onClose();
  }

  Future<void> getMovieDetails({required int streamId}) async {
    // Reset previous state
    isVideoInitialized.value = false;
    _disposeVideoControllers();

    // Fetch details
    await movieCtrl.getMovieDetails(streamId: streamId);

    // Initialize video if URL is available
    final movie = movieCtrl.movie.value;
    if (movie != null && movie.playUrl.isNotEmpty) {
      await _initializePlayer(movie.playUrl);
    }
  }

  Future<void> _initializePlayer(String videoUrl) async {
    try {
      videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );
      await videoPlayerController!.initialize();

      chewieController = ChewieController(
        videoPlayerController: videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: videoPlayerController!.value.aspectRatio,
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
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      Get.snackbar('Error', 'Failed to load video');
    }
  }

  void _disposeVideoControllers() {
    videoPlayerController?.dispose();
    chewieController?.dispose();
    videoPlayerController = null;
    chewieController = null;
  }
}
