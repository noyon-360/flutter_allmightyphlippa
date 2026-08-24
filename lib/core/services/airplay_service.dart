import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thin wrapper around the native iOS `AVRoutePickerView`.
///
/// On iOS, calling [showAirPlayPicker] presents the system AirPlay route
/// picker overlay (the same one the OS shows from Control Center), letting the
/// user beam audio/video to an Apple TV or AirPlay 2 device.
///
/// On every other platform the methods are no-ops.
class AirPlayService {
  AirPlayService._();

  /// Shared singleton instance.
  static final AirPlayService instance = AirPlayService._();

  static const MethodChannel _channel =
      MethodChannel('com.almightyphlippa/airplay');

  /// AirPlay is only available on iOS.
  bool get isAvailable => Platform.isIOS;

  /// Present the native AirPlay route picker overlay.
  ///
  /// Returns `false` (instead of throwing) if the native picker couldn't be
  /// triggered, so callers can tell the user something went wrong rather
  /// than have the request fail silently.
  Future<bool> showAirPlayPicker() async {
    if (!Platform.isIOS) return false;
    try {
      final result = await _channel.invokeMethod<bool>('showAirPlayPicker');
      return result ?? false;
    } catch (e) {
      debugPrint('AirPlayService showAirPlayPicker error: $e');
      return false;
    }
  }
}
