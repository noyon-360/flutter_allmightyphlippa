import 'dart:async';
import 'dart:io';

import 'package:floating/floating.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Unified Picture-in-Picture service for Android and iOS.
///
/// Android: delegates to the `floating` package (uses system PiP API).
/// iOS:     delegates to a native Swift handler via MethodChannel.
///          - For Chewie/video_player content (Live TV): finds the existing
///            AVPlayerLayer in the view hierarchy automatically.
///          - For media_kit/Metal content (Movies & Series): creates a hidden
///            secondary AVPlayer from the supplied [videoUrl] + [positionSeconds].
class PiPService {
  static const _channel = MethodChannel('com.labbytv/pip');

  // Android
  Floating? _floating;
  bool _androidAvailable = false;
  StreamSubscription<PiPStatus>? _statusSub;
  PiPStatus _status = PiPStatus.disabled;

  // iOS
  bool _iosAvailable = false;

  /// Current PiP status (meaningful on Android only; iOS returns disabled).
  PiPStatus get status => _status;

  /// True if PiP is supported and ready on the current platform.
  bool get isAvailable =>
      Platform.isAndroid ? _androidAvailable : _iosAvailable;

  /// Called whenever the Android PiP status changes.
  final void Function(PiPStatus status)? onStatusChanged;

  PiPService({this.onStatusChanged});

  /// Must be called once (e.g. in initState) before [enable] is used.
  Future<void> initialize() async {
    if (Platform.isAndroid) {
      _floating = Floating();
      try {
        _androidAvailable = await _floating!.isPipAvailable;
        _statusSub = _floating!.pipStatusStream.listen(
          (s) {
            _status = s;
            onStatusChanged?.call(s);
          },
          onError: (_) {},
        );
      } catch (e) {
        debugPrint('PiPService Android init: $e');
      }
    } else if (Platform.isIOS) {
      _iosAvailable = await _checkIosAvailability();
    }
  }

  /// The native PiP channel handler is registered asynchronously on app
  /// launch (see AppDelegate.swift), so the very first video screen opened
  /// after a cold start can query this channel before the native side has
  /// finished listening, throwing a MissingPluginException even though PiP
  /// genuinely is supported on the device. Retry briefly instead of
  /// treating that startup race as "unsupported".
  Future<bool> _checkIosAvailability() async {
    const maxAttempts = 4;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await _channel.invokeMethod<bool>('isPiPAvailable') ?? false;
      } catch (e) {
        debugPrint('PiPService iOS availability (attempt ${attempt + 1}): $e');
        if (attempt < maxAttempts - 1) {
          await Future.delayed(const Duration(milliseconds: 250));
        }
      }
    }
    return false;
  }

  /// Activate PiP.
  ///
  /// [videoUrl] and [positionSeconds] are used on iOS only when no
  /// AVPlayerLayer is found in the view hierarchy (i.e. media_kit content).
  Future<void> enable({String? videoUrl, double? positionSeconds}) async {
    if (Platform.isAndroid) {
      if (_floating == null || !_androidAvailable) return;
      try {
        await _floating!
            .enable(const ImmediatePiP(aspectRatio: Rational.landscape()));
      } catch (e) {
        debugPrint('PiPService Android enable: $e');
      }
    } else if (Platform.isIOS) {
      if (!_iosAvailable) return;
      try {
        final args = <String, dynamic>{};
        if (videoUrl != null) args['url'] = videoUrl;
        if (positionSeconds != null) args['position'] = positionSeconds;
        await _channel.invokeMethod<void>('enablePiP', args);
      } catch (e) {
        debugPrint('PiPService iOS enable: $e');
      }
    }
  }

  /// Stop PiP programmatically (iOS only; Android is dismissed by the user).
  Future<void> disable() async {
    if (Platform.isIOS) {
      try {
        await _channel.invokeMethod<void>('disablePiP');
      } catch (_) {}
    }
  }

  void dispose() {
    _statusSub?.cancel();
    _floating = null;
  }
}
