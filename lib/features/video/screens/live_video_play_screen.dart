import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../core/services/airplay_service.dart';
import '../../../core/services/premium_service.dart';

import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/cast_service.dart';
import '../../../core/services/pip_service.dart';
import '../../epg/controllers/epg_timeline_controller.dart';
import '../../epg/widgets/epg_timeline_channel_row.dart';
import '../../epg/widgets/epg_timeline_day_nav.dart';
import '../../epg/widgets/epg_timeline_ruler.dart';
import '../../tv/controllers/live_tv_controller.dart';
import '../../tv/models/live_tv_reponse_model.dart';
import '../controllers/live_video_play_controller.dart';
import '../widgets/live_channel_program_strip.dart';
import '../widgets/live_video_controls.dart';

class LiveVideoPlayScreen extends StatefulWidget {
  final int streamId;
  final String channelName;
  final String channelLogo;

  const LiveVideoPlayScreen({
    super.key,
    required this.streamId,
    required this.channelName,
    this.channelLogo = '',
  });

  @override
  State<LiveVideoPlayScreen> createState() => _LiveVideoPlayScreenState();
}

class _LiveVideoPlayScreenState extends State<LiveVideoPlayScreen>
    with WidgetsBindingObserver {
  // Tagged uniquely per screen instance — switching channels replaces this
  // screen with a new one of the same type, and an untagged Get.put/delete
  // pair would race: the new screen's put() overwrites the old screen's
  // registry entry before the old screen's dispose() runs, so the old
  // screen's delete() ends up tearing down the *new* screen's controller.
  final String _controllerTag = UniqueKey().toString();
  late final LiveVideoPlayController controller;
  final CastService _castService = Get.find<CastService>();
  final ScrollController _epgScrollController = ScrollController();
  bool _showBackToTop = false;
  bool _isFullScreen = false;

  late final PiPService _pipService;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LiveVideoPlayController(), tag: _controllerTag);
    WidgetsBinding.instance.addObserver(this);
    _epgScrollController.addListener(_onEpgScroll);
    _pipService = PiPService();
    _pipService.initialize().then((_) {
      if (mounted) setState(() {});
    });
    // Pause local playback while casting, resume when the cast ends.
    _castService.onCastStarted = () =>
        controller.videoPlayerController?.pause();
    _castService.onCastStopped = () {
      if (mounted) controller.videoPlayerController?.play();
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeLiveVideo(
        streamId: widget.streamId,
        channelName: widget.channelName,
        channelLogo: widget.channelLogo,
      );
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
    // Safety net: if this screen is torn down while still in fullscreen
    // (e.g. the user switches channels, or backgrounds the app instead of
    // using the back gesture), the orientation lock/immersive UI must not
    // leak into the rest of the app — always restore, not just on the
    // explicit exit-fullscreen path.
    if (_isFullScreen) _restoreSystemChrome();
    _epgScrollController.dispose();
    _pipService.dispose();
    _castService.onCastStarted = null;
    _castService.onCastStopped = null;
    WidgetsBinding.instance.removeObserver(this);
    Get.delete<LiveVideoPlayController>(tag: _controllerTag);
    super.dispose();
  }

  void _enterFullScreen() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    setState(() => _isFullScreen = true);
  }

  void _restoreSystemChrome() {
    // Deferred a frame: this is called from PopScope's callback while a
    // pop/back-gesture is still being handled, and issuing the orientation
    // change in that same synchronous callback raced iOS's own scene
    // transition — the OS would reject "portrait" because, for a moment,
    // the view controller it asked still reported the fullscreen
    // landscape-only mask ("UISceneErrorDomain Code=101"). Waiting for the
    // frame to finish first lets that transition settle before we ask.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
    });
  }

  void _exitFullScreen() {
    _restoreSystemChrome();
    if (mounted) setState(() => _isFullScreen = false);
  }

  void _toggleFullScreen() {
    if (_isFullScreen) {
      _exitFullScreen();
    } else {
      _enterFullScreen();
    }
  }

  void _onEpgScroll() {
    // Scroll to Top visibility
    if (_epgScrollController.offset >= 400 && !_showBackToTop) {
      setState(() {
        _showBackToTop = true;
      });
    } else if (_epgScrollController.offset < 400 && _showBackToTop) {
      setState(() {
        _showBackToTop = false;
      });
    }

    if (!Get.isRegistered<LiveTvController>()) return;
    if (_epgScrollController.position.pixels >=
        _epgScrollController.position.maxScrollExtent - 200) {
      Get.find<LiveTvController>().getLiveTvList(isLoadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // While fullscreen, the back gesture/button must exit fullscreen
    // (restoring orientation + system UI) instead of popping this screen —
    // otherwise backing out mid-fullscreen leaves the whole app stuck in a
    // locked landscape orientation with the system bars still hidden.
    return PopScope(
      canPop: !_isFullScreen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isFullScreen) _exitFullScreen();
      },
      child: _buildMainContent(context),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: _isFullScreen
          ? null
          : AppBar(
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
                    icon: const Icon(
                      Icons.picture_in_picture_alt,
                      color: Colors.white,
                    ),
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
        child: Obx(() {
          final videoArea = _buildVideoArea();

          if (_isFullScreen) {
            return Center(child: videoArea);
          }

          // The prev/next program strip sits below the video, not overlaid
          // on top of it (see LiveChannelProgramStrip's doc comment) — only
          // once the stream is actually up, so it doesn't show against a
          // loading/error placeholder.
          final programStrip = controller.isVideoInitialized.value
              ? LiveChannelProgramStrip(
                  streamId: widget.streamId,
                  channelName: widget.channelName,
                )
              : const SizedBox.shrink();

          // Fill the dead space below the video in portrait mode with a
          // scrollable EPG guide — Premium only, both to match the client's
          // ask and because each visible row fires its own EPG request
          // (see EpgTimelineCache) and there's no reason to add that
          // load for users who can't see it anyway. Kept mounted across
          // loading/error/playing so switching channels only swaps the
          // video area instead of blanking the whole page.
          final isPortrait =
              MediaQuery.of(context).orientation == Orientation.portrait;
          // In portrait, videoArea's natural 16:9 height is always well
          // under the available screen height, so it's a plain (non-flex)
          // Column child here — the EPG list's Expanded takes whatever's
          // left, same as before.
          if (isPortrait && PremiumService.to.isPremium.value) {
            return Column(
              children: [
                videoArea,
                programStrip,
                Expanded(child: _buildPortraitEpgList()),
              ],
            );
          }

          // Landscape (non-fullscreen) is different: a 16:9 video at full
          // landscape *width* can want more height than a short landscape
          // *viewport* actually has once the AppBar/strip take their
          // share. A bare Column child gets unbounded height and reported
          // a real overflow instead of shrinking to fit, so this branch
          // specifically needs Flexible to cap it to what's left.
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Center(child: videoArea)),
              programStrip,
            ],
          );
        }),
      ),
      floatingActionButton: (_showBackToTop && !_isFullScreen)
          ? FloatingActionButton(
              onPressed: () {
                _epgScrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: AppColors.red,
              mini: true,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }

  /// The 16:9 video slot — loading spinner, the player, or an error state,
  /// always the same size/position so switching channels (which recreates
  /// this whole screen) only swaps this area instead of blanking the page.
  Widget _buildVideoArea() {
    if (controller.isLoading.value) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.red),
                SizedBox(height: 16),
                Text(
                  'Fetching Stream...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (controller.isVideoInitialized.value &&
        controller.videoPlayerController != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          key: ValueKey('live_video_${widget.streamId}'),
          children: [
            VideoPlayer(controller.videoPlayerController!),
            LiveVideoControls(
              streamId: widget.streamId,
              channelName: widget.channelName,
              videoController: controller.videoPlayerController!,
              isFullScreen: _isFullScreen,
              onToggleFullScreen: _toggleFullScreen,
            ),
            Obx(() {
              if (PremiumService.to.isPremium.value) {
                return const SizedBox.shrink();
              }
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

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.signal_wifi_connected_no_internet_4_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  controller.errorMessage.value ?? 'Failed to load stream.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () =>
                      controller.initializeLiveVideo(streamId: widget.streamId),
                  icon: const Icon(Icons.refresh, color: AppColors.red),
                  label: const Text(
                    'Try Again',
                    style: TextStyle(color: AppColors.red, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// EPG guide shown below the video in portrait mode: a shared time ruler
  /// above a vertically-scrolling grid of channel rows, each a horizontal
  /// strip of previously-aired/current/upcoming program blocks. Reuses
  /// whatever channel list is already loaded on the Live TV tab rather than
  /// re-fetching. Tapping a channel replaces this screen with a fresh
  /// player for that channel — simplest safe way to switch without having
  /// to keep this screen's AppBar/state in sync with an in-place controller
  /// swap.
  Widget _buildPortraitEpgList() {
    if (!Get.isRegistered<LiveTvController>()) return const SizedBox.shrink();
    final liveTvCtrl = Get.find<LiveTvController>();
    final timelineCtrl = Get.find<EpgTimelineController>();

    void openChannel(LiveTvModel channel) {
      if (channel.streamId == widget.streamId) return;
      Get.off(
        () => LiveVideoPlayScreen(
          streamId: channel.streamId,
          channelName: channel.name,
          channelLogo: channel.streamIcon,
        ),
        // LiveVideoPlayScreen isn't a named route, so GetX derives the
        // route name from the widget type — every channel produces the
        // same generated name. With the default preventDuplicates:true,
        // GetX sees that name matching the current route and silently
        // no-ops the navigation, so switching to another channel from
        // within this screen never happened.
        preventDuplicates: false,
      );
    }

    return Obx(() {
      final channels = liveTvCtrl.liveTvList;
      if (channels.isEmpty) return const SizedBox.shrink();

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: EpgTimelineDayNav(timelineCtrl: timelineCtrl),
          ),
          EpgTimelineRuler(timelineCtrl: timelineCtrl),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: Obx(() {
              final day = timelineCtrl.selectedDate.value;
              return ListView.separated(
                controller: _epgScrollController,
                padding: const EdgeInsets.all(12),
                itemCount:
                    channels.length + (liveTvCtrl.isMoreLoading.value ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index >= channels.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.red,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    );
                  }

                  final channel = channels[index];
                  return EpgTimelineChannelRow(
                    streamId: channel.streamId,
                    channelName: channel.name,
                    channelLogo: channel.streamIcon,
                    day: day,
                    onOpenChannel: (_) => openChannel(channel),
                  );
                },
              );
            }),
          ),
        ],
      );
    });
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
                          value: Obx(
                            () => Text(
                              _castService.isCasting.value
                                  ? "Connected"
                                  : "Off",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
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
                            onTap: () async {
                              Navigator.pop(context);
                              final ok = await AirPlayService.instance
                                  .showAirPlayPicker();
                              if (!ok) {
                                Get.snackbar(
                                  'AirPlay',
                                  'Could not open the AirPlay picker. Please try again.',
                                );
                              }
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
                                Get.snackbar(
                                  'Cast',
                                  'No video is currently playing.',
                                );
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
                                Get.snackbar(
                                  'Cast',
                                  'Failed to connect to ${device.name}.',
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.tv,
                                    color: Colors.white,
                                    size: 22,
                                  ),
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
                                        _castService.connectedDevice.value ==
                                            device) {
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
