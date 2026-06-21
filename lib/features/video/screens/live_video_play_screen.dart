import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:chewie/chewie.dart';

import '../../../core/common/widgets/cast_airplay_buttons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/cast_service.dart';
import '../../../core/services/pip_service.dart';
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

class _LiveVideoPlayScreenState extends State<LiveVideoPlayScreen>
    with WidgetsBindingObserver {
  final controller = Get.put(LiveVideoPlayController());
  final CastService _castService = Get.find<CastService>();

  late final PiPService _pipService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pipService = PiPService();
    _pipService.initialize().then((_) {
      if (mounted) setState(() {});
    });
    // Pause local playback while casting, resume when the cast ends.
    _castService.onCastStarted = () => controller.videoPlayerController?.pause();
    _castService.onCastStopped = () {
      if (mounted) controller.videoPlayerController?.play();
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeLiveVideo(streamId: widget.streamId);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused) &&
        _pipService.isAvailable &&
        controller.isVideoInitialized.value) {
      // Live TV: no URL/position needed — iOS uses view-hierarchy AVPlayerLayer,
      // Android uses the floating package directly.
      _pipService.enable();
    }
  }

  @override
  void dispose() {
    _pipService.dispose();
    _castService.onCastStarted = null;
    _castService.onCastStopped = null;
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
          CastAirPlayButtons(
            currentUrl: () => controller.currentPlayUrl,
            title: () => widget.channelName,
          ),
          if (_pipService.isAvailable)
            IconButton(
              icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white),
              onPressed: () => _pipService.enable(),
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
