import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';

import '../../../core/constants/app_colors.dart';
import '../../epg/services/epg_timeline_cache.dart';
import '../controllers/live_video_play_controller.dart';
import 'track_picker_dialog.dart';

/// Fully custom playback controls for the live video area. Tapping the video
/// toggles the overlay: a top row (back, channel name, captions, audio track,
/// picture-in-picture, settings) — kept here rather than in a permanent app
/// bar so the video can use the full width/height in portrait — a center
/// play/pause button, and a bottom bar with the current program's title, live
/// progress (elapsed fraction of its EPG start/end window), and a fullscreen
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
  final LiveVideoPlayController controller;
  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  /// Null when picture-in-picture isn't available on this device.
  final VoidCallback? onPictureInPicture;

  const LiveVideoControls({
    super.key,
    required this.streamId,
    required this.channelName,
    required this.controller,
    required this.isFullScreen,
    required this.onToggleFullScreen,
    required this.onBack,
    required this.onSettings,
    this.onPictureInPicture,
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
    if (oldWidget.streamId != widget.streamId) {
      Get.find<EpgTimelineCache>().ensureLoadedAround(
        widget.streamId,
        DateTime.now(),
      );
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
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
    widget.controller.player.playOrPause();
    _resetHideTimer();
  }

  void _showSubtitles() {
    _resetHideTimer();
    final c = widget.controller;
    showTrackPickerDialog<SubtitleTrack>(
      context: context,
      title: 'Captions',
      emptyText: 'No captions available',
      tracks: c.availableSubtitleTracks,
      isSelected: (t) => c.currentSubtitleTrack.value == t,
      labelFor: subtitleTrackLabel,
      onSelect: c.setSubtitleTrack,
    );
  }

  void _showAudioTracks() {
    _resetHideTimer();
    final c = widget.controller;
    showTrackPickerDialog<AudioTrack>(
      context: context,
      title: 'Audio Track',
      emptyText: 'No audio tracks available',
      tracks: c.availableAudioTracks,
      isSelected: (t) => c.currentAudioTrack.value == t,
      labelFor: audioTrackLabel,
      onSelect: c.setAudioTrack,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

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
          child: Obx(
            () => controller.isBuffering.value
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
                            controller.isPlaying.value
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
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
                  top: 0,
                  child: SafeArea(bottom: false, child: _buildTopBar()),
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

  Widget _topIcon(IconData icon, VoidCallback onPressed, {String? tooltip}) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      iconSize: 24,
      color: Colors.white,
      onPressed: () {
        _resetHideTimer();
        onPressed();
      },
      icon: Icon(icon),
    );
  }

  Widget _buildTopBar() {
    final c = widget.controller;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
      child: Row(
        children: [
          _topIcon(Icons.arrow_back, widget.onBack, tooltip: 'Back'),
          Expanded(
            child: Text(
              widget.channelName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Only offered when the stream actually carries the tracks.
          Obx(() {
            final showCaptions = c.hasSubtitleTracks;
            final showAudio = c.hasMultipleAudioTracks;
            final captionsOn =
                c.currentSubtitleTrack.value != null &&
                c.currentSubtitleTrack.value != SubtitleTrack.no();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showCaptions)
                  _topIcon(
                    captionsOn
                        ? Icons.closed_caption
                        : Icons.closed_caption_off,
                    _showSubtitles,
                    tooltip: 'Captions',
                  ),
                if (showAudio)
                  _topIcon(Icons.audiotrack, _showAudioTracks, tooltip: 'Audio'),
              ],
            );
          }),
          if (widget.onPictureInPicture != null)
            _topIcon(
              Icons.picture_in_picture_alt,
              widget.onPictureInPicture!,
              tooltip: 'Picture in picture',
            ),
          _topIcon(Icons.settings, widget.onSettings, tooltip: 'Settings'),
        ],
      ),
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
