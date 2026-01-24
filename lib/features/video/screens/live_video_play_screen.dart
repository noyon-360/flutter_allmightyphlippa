import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/live_video_play_controller.dart';

class LiveVideoPlayScreen extends StatefulWidget {
  final int streamId;
  final String channelName;

  const LiveVideoPlayScreen({
    super.key,
    required this.streamId,
    required this.channelName,
  });

  @override
  State<LiveVideoPlayScreen> createState() => _LiveVideoPlayScreenState();
}

class _LiveVideoPlayScreenState extends State<LiveVideoPlayScreen> {
  final controller = Get.put(LiveVideoPlayController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeLiveVideo(streamId: widget.streamId);
    });
  }

  @override
  void dispose() {
    Get.delete<LiveVideoPlayController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          widget.channelName,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Center(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.red),
                SizedBox(height: 16),
                Text(
                  'Fetching Stream...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            );
          }

          if (controller.isVideoInitialized.value) {
            return AspectRatio(
              aspectRatio: 16 / 9,
              child: Video(controller: controller.videoController),
            );
          }

          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 48),
              SizedBox(height: 16),
              Text(
                'Failed to load stream',
                style: TextStyle(color: Colors.white),
              ),
            ],
          );
        }),
      ),
    );
  }
}
