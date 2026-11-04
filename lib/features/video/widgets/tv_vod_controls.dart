import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/constants/app_colors.dart';

/// Remote-driven controls for the movie/series player on Android TV, passed
/// as `Video(controls:)` so the same widget runs embedded and in media_kit's
/// fullscreen route.
///
/// media_kit's desktop controls only appear on mouse hover, which a remote
/// never sends, so on TV they stayed invisible (a black frame with no way to
/// see position or state). Here every key brings the overlay back, and it
/// hides again after [_hideAfter] unless playback is paused.
///
/// The overlay itself has no focusable buttons: all input is keys on this
/// one focus node, so nothing invisible can be "pressed" while it's hidden.
class TvVodControls extends StatefulWidget {
  final Player player;
  final String Function() title;

  const TvVodControls({super.key, required this.player, required this.title});

  @override
  State<TvVodControls> createState() => _TvVodControlsState();
}

class _TvVodControlsState extends State<TvVodControls> {
  static const _hideAfter = Duration(seconds: 5);
  static const _seekStep = Duration(seconds: 10);
  static const _seekStepMedia = Duration(seconds: 30);

  final FocusNode _focus = FocusNode(debugLabel: 'TvVodControls');
  final List<StreamSubscription> _subs = [];
  Timer? _hideTimer;
  bool _visible = true;

  late bool _playing = widget.player.state.playing;
  late bool _buffering = widget.player.state.buffering;
  late Duration _position = widget.player.state.position;
  late Duration _duration = widget.player.state.duration;
  late Duration _buffer = widget.player.state.buffer;

  /// Where a held Left/Right is heading. Seeking from `state.position` on
  /// every key repeat would stall: mpv hasn't reported the previous seek yet,
  /// so each repeat would jump from the same spot.
  Duration? _seekTarget;

  @override
  void initState() {
    super.initState();
    final s = widget.player.stream;
    _subs.addAll([
      s.playing.listen((v) {
        setState(() => _playing = v);
        // Paused: keep the overlay up so the viewer sees why nothing moves.
        v ? _resetHideTimer() : _show();
      }),
      s.buffering.listen((v) => setState(() => _buffering = v)),
      s.position.listen((v) {
        if (_visible) setState(() => _position = v);
        _position = v;
      }),
      s.duration.listen((v) => setState(() => _duration = v)),
      s.buffer.listen((v) {
        if (_visible) setState(() => _buffer = v);
        _buffer = v;
      }),
    ]);
    _resetHideTimer();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _hideTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideAfter, () {
      if (widget.player.state.playing) setState(() => _visible = false);
    });
  }

  void _show() {
    setState(() => _visible = true);
    _resetHideTimer();
  }

  void _seekBy(Duration offset) {
    final from = _seekTarget ?? _position;
    var to = from + offset;
    if (to < Duration.zero) to = Duration.zero;
    if (_duration > Duration.zero && to > _duration) to = _duration;
    _seekTarget = to;
    setState(() => _position = to);
    widget.player.seek(to);
    _show();
  }

  static bool _isSelect(LogicalKeyboardKey k) =>
      k == LogicalKeyboardKey.select ||
      k == LogicalKeyboardKey.enter ||
      k == LogicalKeyboardKey.numpadEnter ||
      k == LogicalKeyboardKey.gameButtonA;

  static bool _isPlayKey(LogicalKeyboardKey k) =>
      k == LogicalKeyboardKey.mediaPlayPause ||
      k == LogicalKeyboardKey.mediaPlay ||
      k == LogicalKeyboardKey.mediaPause ||
      k == LogicalKeyboardKey.space;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (event is KeyUpEvent) {
      if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.arrowRight) {
        _seekTarget = null;
      }
      return KeyEventResult.ignored;
    }
    final down = event is KeyDownEvent;
    final fullscreen = isFullscreen(context);

    // Seeking repeats while the key is held.
    if (key == LogicalKeyboardKey.arrowLeft) {
      _seekBy(-_seekStep);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _seekBy(_seekStep);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaRewind) {
      _seekBy(-_seekStepMedia);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaFastForward) {
      _seekBy(_seekStepMedia);
      return KeyEventResult.handled;
    }
    // A held OK / play key must not toggle over and over; other repeats
    // (Up/Down focus traversal, Back) pass through.
    if (!down) {
      return _isSelect(key) || _isPlayKey(key)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.space) {
      widget.player.playOrPause();
      _show();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaPlay) {
      widget.player.play();
      _show();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaPause) {
      widget.player.pause();
      _show();
      return KeyEventResult.handled;
    }
    if (_isSelect(key)) {
      if (!fullscreen) {
        enterFullscreen(context);
      } else if (!_visible) {
        // First press only reveals the overlay — never act on something the
        // viewer can't see yet.
        _show();
      } else {
        widget.player.playOrPause();
        _show();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      _show();
      // Embedded: let focus move on to the buttons / episodes around the
      // player. Fullscreen has nowhere else to go.
      return fullscreen ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    // Back in fullscreen goes through the route (media_kit pops it).
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final fullscreen = isFullscreen(context);
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      onFocusChange: (has) {
        if (has) _show();
        setState(() {});
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Embedded, the player is one of several focus targets on the
          // page: outline it so the viewer knows OK will go fullscreen.
          if (!fullscreen && _focus.hasFocus)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.red, width: 3),
                ),
              ),
            ),
          if (_buffering)
            const Center(
              child: CircularProgressIndicator(color: AppColors.red),
            ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: _buildOverlay(fullscreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(bool fullscreen) {
    final scale = fullscreen ? 1.0 : 0.75;
    final total = _duration.inMilliseconds;
    final played = total > 0 ? _position.inMilliseconds / total : 0.0;
    final buffered = total > 0 ? _buffer.inMilliseconds / total : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (!_buffering)
          Center(
            child: Container(
              padding: EdgeInsets.all(14 * scale),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playing ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 48 * scale,
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.transparent,
                ],
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              32 * scale,
              48 * scale,
              32 * scale,
              24 * scale,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12 * scale),
                _ProgressBar(
                  played: played.clamp(0.0, 1.0),
                  buffered: buffered.clamp(0.0, 1.0),
                ),
                SizedBox(height: 8 * scale),
                Row(
                  children: [
                    Text(
                      formatPlaybackTime(_position),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14 * scale,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatPlaybackTime(_duration),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14 * scale,
                      ),
                    ),
                  ],
                ),
                if (fullscreen) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'OK  play / pause     Left / Right  10 s     Back  exit',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double played;
  final double buffered;

  const _ProgressBar({required this.played, required this.buffered});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.white24),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: buffered,
              child: const ColoredBox(color: Colors.white38),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: played,
              child: const ColoredBox(color: AppColors.red),
            ),
          ],
        ),
      ),
    );
  }
}

/// `1:02:03` past an hour, otherwise `02:03`.
String formatPlaybackTime(Duration d) {
  if (d.isNegative) d = Duration.zero;
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}
