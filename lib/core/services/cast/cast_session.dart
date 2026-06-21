import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'cast_device.dart';
import 'cast_protocol.dart';

enum CastSessionState { connecting, launching, connected, closed }

class CastSession {
  static const _nsConnection = 'urn:x-cast:com.google.cast.tp.connection';
  static const _nsHeartbeat = 'urn:x-cast:com.google.cast.tp.heartbeat';
  static const _nsReceiver = 'urn:x-cast:com.google.cast.receiver';
  static const _nsMedia = 'urn:x-cast:com.google.cast.media';
  static const _defaultAppId = 'CC1AD845';

  final CastDevice device;

  SecureSocket? _socket;
  StreamSubscription<List<int>>? _socketSub;
  Timer? _heartbeatTimer;

  final _stateCtrl = StreamController<CastSessionState>.broadcast();
  Stream<CastSessionState> get stateStream => _stateCtrl.stream;

  CastSessionState _state = CastSessionState.connecting;
  CastSessionState get state => _state;

  final _pendingBytes = <int>[];
  String _appTransportId = 'receiver-0';
  int _requestId = 1;

  CastSession({required this.device});

  Future<void> connect() async {
    _setState(CastSessionState.connecting);
    try {
      _socket = await SecureSocket.connect(
        device.host,
        device.port,
        onBadCertificate: (_) => true,
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('CastSession connect error: $e');
      _setState(CastSessionState.closed);
      rethrow;
    }

    _socketSub = _socket!.listen(
      _onData,
      onError: (e) {
        debugPrint('CastSession socket error: $e');
        _close();
      },
      onDone: _close,
    );

    _send(_nsConnection, 'receiver-0', {'type': 'CONNECT', 'origin': {}});
    _setState(CastSessionState.launching);
    _send(_nsReceiver, 'receiver-0', {
      'type': 'LAUNCH',
      'appId': _defaultAppId,
      'requestId': _nextId(),
    });

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _send(_nsHeartbeat, 'receiver-0', {'type': 'PING'});
    });
  }

  void loadMedia(String url, {String title = '', String? imageUrl}) {
    if (_state != CastSessionState.connected) return;
    final isLive = url.contains('.m3u8') || url.contains('/live/');
    _send(_nsMedia, _appTransportId, {
      'type': 'LOAD',
      'autoPlay': true,
      'currentTime': 0,
      'requestId': _nextId(),
      'media': {
        'contentId': url,
        'contentType': _contentType(url),
        'streamType': isLive ? 'LIVE' : 'BUFFERED',
        'metadata': {
          'type': 0,
          'metadataType': 0,
          'title': title,
          if (imageUrl != null && imageUrl.isNotEmpty)
            'images': [
              {'url': imageUrl}
            ],
        },
      },
    });
  }

  void stopApp() {
    try {
      _send(_nsReceiver, 'receiver-0', {
        'type': 'STOP',
        'requestId': _nextId(),
      });
    } catch (_) {}
  }

  Future<void> disconnect() async {
    try {
      _send(_nsConnection, 'receiver-0', {'type': 'CLOSE'});
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 200));
    _close();
  }

  // ---------- private ----------

  void _onData(List<int> data) {
    _pendingBytes.addAll(data);

    while (_pendingBytes.length >= 4) {
      final msgLen = ByteData.view(
        Uint8List.fromList(_pendingBytes.sublist(0, 4)).buffer,
      ).getUint32(0, Endian.big);

      if (_pendingBytes.length < 4 + msgLen) break;

      final msgBytes =
          Uint8List.fromList(_pendingBytes.sublist(4, 4 + msgLen));
      _pendingBytes.removeRange(0, 4 + msgLen);

      _handleMessage(msgBytes);
    }
  }

  void _handleMessage(Uint8List bytes) {
    final msg = decodeCastMessage(bytes);
    if (msg == null) return;

    final type = msg['type'] as String?;

    if (type == 'PING') {
      _send(_nsHeartbeat, 'receiver-0', {'type': 'PONG'});
      return;
    }

    if (type == 'RECEIVER_STATUS') {
      final apps = (msg['status']?['applications'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .toList();
      final app = apps?.firstWhere(
        (a) => a['appId'] == _defaultAppId,
        orElse: () => <String, dynamic>{},
      );

      if (app != null && app.isNotEmpty) {
        final transportId = app['transportId'] as String?;
        if (transportId != null && transportId.isNotEmpty) {
          _appTransportId = transportId;
          _send(_nsConnection, _appTransportId,
              {'type': 'CONNECT', 'origin': {}});
          _setState(CastSessionState.connected);
        }
      }
    }
  }

  void _send(String namespace, String dest, Map<String, dynamic> payload) {
    if (_socket == null) return;
    try {
      _socket!.add(encodeCastMessage(
        sourceId: 'sender-0',
        destinationId: dest,
        namespace: namespace,
        payloadUtf8: jsonEncode(payload),
      ));
    } catch (e) {
      debugPrint('CastSession _send error: $e');
    }
  }

  void _setState(CastSessionState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  void _close() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _socketSub?.cancel();
    _socketSub = null;
    _socket?.destroy();
    _socket = null;
    _pendingBytes.clear();
    if (_state != CastSessionState.closed) {
      _setState(CastSessionState.closed);
    }
    if (!_stateCtrl.isClosed) _stateCtrl.close();
  }

  int _nextId() => _requestId++;

  String _contentType(String url) {
    final l = url.toLowerCase();
    if (l.contains('.m3u8')) return 'application/x-mpegurl';
    if (l.contains('.mpd')) return 'application/dash+xml';
    if (l.contains('.webm')) return 'video/webm';
    if (l.contains('.mkv')) return 'video/x-matroska';
    return 'video/mp4';
  }
}
