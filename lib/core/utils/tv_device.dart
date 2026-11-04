import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutx_core/flutx_core.dart';

/// Whether the app is running on Android TV / Google TV.
///
/// Read once at startup (see AppInitializer) from MainActivity's
/// `labby/device` channel, so widgets can branch on [isTv] synchronously.
/// Always false on phones, tablets and iOS — every TV-only behaviour is
/// gated on it so the phone app is unchanged.
class TvDevice {
  static const _channel = MethodChannel('labby/device');

  static bool _isTv = false;

  static bool get isTv => _isTv;

  static Future<void> init() async {
    if (!Platform.isAndroid) return;
    try {
      _isTv = await _channel.invokeMethod<bool>('isTv') ?? false;
    } catch (e) {
      DPrint.error("TvDevice.isTv check failed: $e");
    }
  }
}
