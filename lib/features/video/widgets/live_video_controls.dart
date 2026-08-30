import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../../epg/models/epg_program_model.dart';
import '../../epg/services/epg_timeline_cache.dart';
import '../../epg/widgets/epg_program_info_sheet.dart';

const double _kChipWidth = 112;
const int _kContextCount = 10; // programs shown before/after the current one

/// Fully custom playback controls for the live video area — replaces the
/// default Chewie chrome. Tapping the video toggles a play/pause button
/// plus a bottom bar: the current program's title, live progress (elapsed
/// fraction of its EPG start/end window), and a horizontal strip of the
/// surrounding 10 previous + 10 next programs on this channel, sourced from
/// [EpgTimelineCache] (same cache the EPG grid uses, so revisiting a
/// channel/day already fetched is free).
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
  bool _didAutoScrollStrip = false;
  Timer? _hideTimer;
  Timer? _tickTimer;
  final ScrollController _stripController = ScrollController();

  @override
  void initState() {
    super.initState();
    Get.find<EpgTimelineCache>().ensureLoadedAround(
      widget.streamId,
      DateTime.now(),
    );
    widget.videoController.addListener(_onVideoValueChanged);
    _resetHideTimer();
    // The progress bar and current-program highlight advance with the wall
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
      _didAutoScrollStrip = false;
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
    _stripController.dispose();
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
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background tap-to-toggle layer, sized to the whole video area but
        // placed *behind* the chrome below as a sibling — not wrapped
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
        if (widget.videoController.value.isBuffering)
          const IgnorePointer(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.red),
            ),
          ),
        AnimatedOpacity(
          opacity: _controlsVisible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !_controlsVisible,
            child: _buildChrome(),
          ),
        ),
      ],
    );
  }

  Widget _buildChrome() {
    final isPlaying = widget.videoController.value.isPlaying;

    // A Column, not Center()+Positioned(bottom) independently stacked —
    // the bottom bar (title/progress/program strip) can be tall relative
    // to a 16:9 video area on a phone, and Center() ignores it entirely
    // when placing the play/pause button, so on a short video the two
    // regions' hit-test areas actually overlapped: taps meant for
    // play/pause could land on the bottom bar's title row or a program
    // chip instead. A Column gives the button `Expanded` — whatever space
    // is actually left above the bottom bar — so the two never compete
    // for the same pixels.
    return Stack(
      children: [
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.black26),
            child: SizedBox.expand(),
          ),
        ),
        Column(
          children: [
            Expanded(
              child: Center(
                child: Material(
                  color: Colors.black45,
                  shape: const CircleBorder(),
                  child: IconButton(
                    iconSize: 36,
                    color: Colors.white,
                    onPressed: _togglePlayPause,
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  ),
                ),
              ),
            ),
            Obx(() => _buildBottomBar()),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final cache = Get.find<EpgTimelineCache>();
    final now = DateTime.now();
    final loaded = cache.isLoadedAround(widget.streamId, now);
    final programs = cache.peekAround(widget.streamId, now);

    final currentIndex = programs.indexWhere(
      (p) => p.startTime.isBefore(now) && p.endTime.isAfter(now),
    );
    final current = currentIndex >= 0 ? programs[currentIndex] : null;

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
          const SizedBox(height: 10),
          SizedBox(
            height: 46,
            child: !loaded
                ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppColors.red,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : programs.isEmpty
                ? const SizedBox.shrink()
                : _buildStrip(programs, currentIndex, now),
          ),
        ],
      ),
    );
  }

  Widget _buildStrip(
    List<EpgProgramModel> programs,
    int currentIndex,
    DateTime now,
  ) {
    final start = currentIndex >= 0
        ? (currentIndex - _kContextCount).clamp(0, programs.length)
        : 0;
    final end = currentIndex >= 0
        ? (currentIndex + _kContextCount + 1).clamp(0, programs.length)
        : programs.length;
    final visible = programs.sublist(start, end);
    final visibleCurrentIndex = currentIndex >= 0 ? currentIndex - start : -1;

    if (!_didAutoScrollStrip && visibleCurrentIndex >= 0) {
      _didAutoScrollStrip = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_stripController.hasClients) return;
        final offset =
            (visibleCurrentIndex * (_kChipWidth + 6)) -
            (_stripController.position.viewportDimension / 2) +
            (_kChipWidth / 2);
        _stripController.jumpTo(
          offset.clamp(0.0, _stripController.position.maxScrollExtent),
        );
      });
    }

    return ListView.separated(
      controller: _stripController,
      scrollDirection: Axis.horizontal,
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (context, index) {
        final program = visible[index];
        final isCurrent = index == visibleCurrentIndex;
        final isPast = !isCurrent && program.endTime.isBefore(now);
        final isFuture = !isCurrent && !isPast;

        return GestureDetector(
          onTap: () {
            _resetHideTimer();
            showEpgProgramInfoSheet(
              context,
              program: program,
              streamId: widget.streamId,
              channelName: widget.channelName,
              isFuture: isFuture,
            );
          },
          child: Container(
            width: _kChipWidth,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.red.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: isCurrent ? Border.all(color: AppColors.red) : null,
            ),
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.title,
                  style: TextStyle(
                    color: isPast ? Colors.white54 : Colors.white,
                    fontSize: 11,
                    fontWeight: isCurrent
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  program.timeRange,
                  style: TextStyle(
                    color: isCurrent ? Colors.white70 : Colors.white38,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
