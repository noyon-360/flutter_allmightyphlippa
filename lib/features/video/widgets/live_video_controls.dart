import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../../epg/services/epg_timeline_cache.dart';

/// Fully custom playback controls for the live video area — replaces the
/// default Chewie chrome. Tapping the video toggles a center play/pause
/// button plus a bottom bar: the current program's title, live progress
/// (elapsed fraction of its EPG start/end window), and a fullscreen
/// toggle. The surrounding-programs strip lives outside the player, below
/// it, as [LiveChannelProgramStrip] — see that widget's doc comment for why.
///
/// The play/pause button and the buffering spinner share one `Center()` in
/// [build] rather than each computing their own — they used to drift apart
/// (the spinner centered in the full video frame, the button centered only
/// in the space *above* the bottom bar) whenever the bottom bar had any
/// height, which is confusing since only one of them is ever showing at a
/// time. The spinner still isn't gated by [_controlsVisible]: buffering can
/// happen whether or not the user is currently looking at the controls.
class LiveVideoControls extends StatefulWidget {
  final int streamId;
  final String channelName;
  final VideoPlayerController videoController;
  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  const LiveVideoControls({
    super.key,
    required this.streamId,
    required this.channelName,
    required this.videoController,
    required this.isFullScreen,
    required this.onToggleFullScreen,
  });

  @override
  State<LiveVideoControls> createState() => _LiveVideoControlsState();
}

class _LiveVideoControlsState extends State<LiveVideoControls> {
  bool _controlsVisible = true;
  Timer? _hideTimer;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    Get.find<EpgTimelineCache>().ensureLoadedAround(
      widget.streamId,
      DateTime.now(),
    );
    widget.videoController.addListener(_onVideoValueChanged);
    _resetHideTimer();
    // The progress bar and current-program title advance with the wall
    // clock even when no video/player event fires — repaint periodically
    // so they don't go stale during a long-idle live view.
    _tickTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant LiveVideoControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoController != widget.videoController) {
      oldWidget.videoController.removeListener(_onVideoValueChanged);
      widget.videoController.addListener(_onVideoValueChanged);
    }
    if (oldWidget.streamId != widget.streamId) {
      Get.find<EpgTimelineCache>().ensureLoadedAround(
        widget.streamId,
        DateTime.now(),
      );
    }
  }

  @override
  void dispose() {
    widget.videoController.removeListener(_onVideoValueChanged);
    _hideTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  void _onVideoValueChanged() {
    if (mounted) setState(() {});
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _resetHideTimer();
  }

  void _togglePlayPause() {
    final video = widget.videoController;
    if (video.value.isPlaying) {
      video.pause();
    } else {
      video.play();
    }
    _resetHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final isBuffering = widget.videoController.value.isBuffering;
    final isPlaying = widget.videoController.value.isPlaying;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background tap-to-toggle layer, sized to the whole video area but
        // placed *behind* everything below as a sibling — not wrapped
        // around it. Nesting a full-area GestureDetector around the
        // buttons made every button tap race the background toggle in the
        // same gesture arena, which is what made play/pause feel like it
        // "did nothing": tapping the button could also fire the toggle and
        // instantly hide the whole overlay (button included) before the
        // state change was visible. As siblings, an on-top button's own
        // GestureDetector always claims its own taps first; only taps that
        // land outside any button fall through to this layer.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleControls,
          ),
        ),
        // One Center() shared by the spinner and the button (see the class
        // doc comment) — only one of the two is ever present at a time.
        Center(
          child: isBuffering
              ? const IgnorePointer(
                  child: CircularProgressIndicator(color: AppColors.red),
                )
              : AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: Material(
                      color: Colors.black45,
                      shape: const CircleBorder(),
                      child: IconButton(
                        iconSize: 36,
                        color: Colors.white,
                        onPressed: _togglePlayPause,
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        AnimatedOpacity(
          opacity: _controlsVisible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !_controlsVisible,
            child: Stack(
              children: [
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black26),
                    child: SizedBox.expand(),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Obx(() => _buildBottomBar()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final cache = Get.find<EpgTimelineCache>();
    final now = DateTime.now();
    final programs = cache.peekAround(widget.streamId, now);

    final current = programs.firstWhereOrNull(
      (p) => p.startTime.isBefore(now) && p.endTime.isAfter(now),
    );

    final totalSeconds = current == null
        ? 0
        : current.endTime.difference(current.startTime).inSeconds;
    final elapsedFraction = (current == null || totalSeconds <= 0)
        ? 0.0
        : (now.difference(current.startTime).inSeconds / totalSeconds).clamp(
            0.0,
            1.0,
          );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 28, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  current?.title ?? widget.channelName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (current != null)
                Text(
                  current.timeRange,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 22,
                color: Colors.white,
                onPressed: () {
                  _resetHideTimer();
                  widget.onToggleFullScreen();
                },
                icon: Icon(
                  widget.isFullScreen
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                ),
              ),
            ],
          ),
          if (current != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: elapsedFraction,
                minHeight: 3,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(AppColors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
