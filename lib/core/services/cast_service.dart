import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'cast/cast_device.dart';
import 'cast/cast_discovery.dart';
import 'cast/cast_session.dart';

export 'cast/cast_device.dart';

class CastService extends GetxService {
  final _discovery = CastDiscovery();

  final RxBool isCasting = false.obs;
  final RxBool isScanning = false.obs;
  final RxBool isConnecting = false.obs;
  final RxList<CastDevice> availableDevices = <CastDevice>[].obs;
  final Rxn<CastDevice> connectedDevice = Rxn<CastDevice>();

  CastSession? _session;
  StreamSubscription<CastSessionState>? _stateSub;

  void Function()? onCastStarted;
  void Function()? onCastStopped;

  Future<CastService> initialize() async => this;

  Future<List<CastDevice>> startScan({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    isScanning.value = true;
    try {
      final devices = await _discovery.search(timeout: timeout);
      availableDevices.assignAll(devices);
      return devices;
    } catch (e) {
      debugPrint('CastService scan error: $e');
      availableDevices.clear();
      return [];
    } finally {
      isScanning.value = false;
    }
  }

  Future<void> connectToDevice(
    CastDevice device, {
    String url = '',
    String title = '',
    String? imageUrl,
  }) async {
    isConnecting.value = true;
    try {
      await _closeSession();

      final session = CastSession(device: device);
      _session = session;
      connectedDevice.value = device;

      _stateSub = session.stateStream.listen((state) {
        if (state == CastSessionState.connected) {
          if (url.isNotEmpty) {
            session.loadMedia(url, title: title, imageUrl: imageUrl);
          }
          isCasting.value = true;
          isConnecting.value = false;
          onCastStarted?.call();
        } else if (state == CastSessionState.closed) {
          _handleSessionClosed();
        }
      });

      await session.connect();
    } catch (e) {
      debugPrint('CastService connectToDevice error: $e');
      await _closeSession();
      isConnecting.value = false;
      rethrow;
    }
  }

  Future<void> stopCasting() async {
    _session?.stopApp();
    await Future.delayed(const Duration(milliseconds: 300));
    await _closeSession();
  }

  Future<void> _closeSession() async {
    await _stateSub?.cancel();
    _stateSub = null;
    final s = _session;
    _session = null;
    await s?.disconnect();
    _resetCastState();
  }

  void _handleSessionClosed() {
    _session = null;
    _stateSub?.cancel();
    _stateSub = null;
    _resetCastState();
  }

  void _resetCastState() {
    final wasCasting = isCasting.value || connectedDevice.value != null;
    connectedDevice.value = null;
    isCasting.value = false;
    isConnecting.value = false;
    if (wasCasting) onCastStopped?.call();
  }

  @override
  void onClose() {
    _stateSub?.cancel();
    super.onClose();
  }
}
