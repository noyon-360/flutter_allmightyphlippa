import 'dart:io';

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:chewie/chewie.dart';
import '../../../core/services/airplay_service.dart';
import '../../../core/services/premium_service.dart';

import '../../../core/common/widgets/tv_focus_wrapper.dart';
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
          // CastAirPlayButtons(
          //   currentUrl: () => controller.currentPlayUrl,
          //   title: () => widget.channelName,
          // ),
          if (_pipService.isAvailable)
            IconButton(
              icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white),
              onPressed: () => _pipService.enable(),
            ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showSettingsDialog(context),
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
                child: Stack(
                  children: [
                    Chewie(
                      controller: controller.chewieController!,
                      key: ValueKey('live_video_${widget.streamId}'),
                    ),
                    Obx(() {
                      if (PremiumService.to.isPremium.value) return const SizedBox.shrink();
                      return const Positioned(
                        bottom: 56,
                        right: 12,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.5,
                            child: Text(
                              'LabbyTV',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.signal_wifi_connected_no_internet_4_rounded, color: Colors.redAccent, size: 56),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    controller.errorMessage.value ?? 'Failed to load stream.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => controller.initializeLiveVideo(streamId: widget.streamId),
                  icon: const Icon(Icons.refresh, color: AppColors.red),
                  label: const Text('Try Again', style: TextStyle(color: AppColors.red, fontSize: 15)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final outerContext = context;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                color: AppColors.containerBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3D3D3D),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Settings",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TvFocusWrapper(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Google Cast
                        _buildSettingRow(
                          label: "Google Cast",
                          value: Obx(() => Text(
                            _castService.isCasting.value
                                ? "Connected"
                                : "Off",
                            style: const TextStyle(color: Colors.white),
                          )),
                          onTap: () {
                            if (_castService.isCasting.value) {
                              _castService.stopCasting();
                              Navigator.pop(context);
                            } else {
                              Navigator.pop(context);
                              _showCastPickerDialog(outerContext);
                            }
                          },
                        ),
                        if (Platform.isIOS) ...[
                          const SizedBox(height: 16),
                          _buildSettingRow(
                            label: "AirPlay",
                            value: const Text(
                              "Available",
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              AirPlayService.instance.showAirPlayPicker();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingRow({
    required String label,
    required Widget value,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        TvFocusWrapper(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                value,
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCastPickerDialog(BuildContext context) {
    _castService.startScan();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cast',
      pageBuilder: (ctx, _, _) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(ctx).size.width * 0.8,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: AppColors.containerBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3D3D3D),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cast, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Cast to device",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        TvFocusWrapper(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Obx(() {
                      if (_castService.isScanning.value &&
                          _castService.availableDevices.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  color: AppColors.red,
                                  strokeWidth: 3,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Searching for devices...",
                                style: TextStyle(color: AppColors.primaryGray),
                              ),
                            ],
                          ),
                        );
                      }

                      if (_castService.availableDevices.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cast,
                                color: AppColors.primaryGray,
                                size: 36,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "No Chromecast devices found nearby. "
                                "Make sure your device is on the same WiFi network.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.primaryGray,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TvFocusWrapper(
                                onTap: () => _castService.startScan(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Text(
                                    "Retry",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _castService.availableDevices.length,
                        itemBuilder: (context, index) {
                          final device = _castService.availableDevices[index];
                          return TvFocusWrapper(
                            onTap: () async {
                              final url = controller.currentPlayUrl;
                              if (url == null || url.isEmpty) {
                                Get.snackbar('Cast', 'No video is currently playing.');
                                return;
                              }
                              try {
                                await _castService.connectToDevice(
                                  device,
                                  url: url,
                                  title: widget.channelName,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (_) {
                                if (ctx.mounted) Navigator.pop(ctx);
                                Get.snackbar('Cast', 'Failed to connect to ${device.name}.');
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.tv, color: Colors.white, size: 22),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      device.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Obx(() {
                                    if (_castService.isConnecting.value &&
                                        _castService.connectedDevice.value == device) {
                                      return const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: AppColors.red,
                                          strokeWidth: 2,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
