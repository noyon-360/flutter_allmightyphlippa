import 'dart:io';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:chewie/chewie.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/live_video_play_controller.dart';
import 'package:floating/floating.dart';

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

class _LiveVideoPlayScreenState extends State<LiveVideoPlayScreen>
    with WidgetsBindingObserver {
  final controller = Get.put(LiveVideoPlayController());

  Floating? pip;
  bool isPipAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) {
      pip = Floating();
      _checkPipAvailability();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeLiveVideo(streamId: widget.streamId);
    });
  }

  Future<void> _checkPipAvailability() async {
    if (pip == null) return;
    try {
      isPipAvailable = await pip!.isPipAvailable;
    } catch (e) {
      debugPrint('PiP availability check error: $e');
      isPipAvailable = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused) &&
        isPipAvailable &&
        pip != null &&
        controller.isVideoInitialized.value) {
      pip!.enable(const ImmediatePiP(aspectRatio: Rational.landscape()));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Get.delete<LiveVideoPlayController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Temporarily disabled PiPSwitcher to debug blank screen issue
    return _buildMainContent(context);
  }

  Widget _buildMainContent(BuildContext context) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white),
            onPressed: () {
              if (isPipAvailable && pip != null) {
                pip!.enable(
                  const ImmediatePiP(aspectRatio: Rational.landscape()),
                );
              } else {
                Get.snackbar('Error', 'PiP is not available on this device');
              }
            },
          ),
        ],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.black,
        child: Center(
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

            if (controller.isVideoInitialized.value &&
                controller.chewieController != null) {
              return AspectRatio(
                aspectRatio: 16 / 9,
                child: Chewie(
                  controller: controller.chewieController!,
                  key: ValueKey('live_video_${widget.streamId}'),
                ),
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
      ),
    );
  }
}
