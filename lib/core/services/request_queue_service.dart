import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutx_core/core/debug_print.dart';
import 'connectivity_service.dart';
import 'hive_storage_service.dart';
import '../api/api_client.dart';

class QueuedRequest {
  final String method;
  final String endpoint;
  final dynamic data;
  final String timestamp;

  QueuedRequest({
    required this.method,
    required this.endpoint,
    this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'method': method,
    'endpoint': endpoint,
    'data': data,
    'timestamp': timestamp,
  };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
    method: json['method'],
    endpoint: json['endpoint'],
    data: json['data'],
    timestamp: json['timestamp'],
  );
}

class RequestQueueService {
  static const String _boxName = 'request_queue_box';
  late Box _box;
  bool _isProcessing = false;

  static final RequestQueueService _instance = RequestQueueService._internal();
  factory RequestQueueService() => _instance;
  RequestQueueService._internal();

  Future<void> initialize() async {
    if (!HiveStorageService.isInitialized) {
      DPrint.error('Cannot initialize RequestQueueService: Hive is not initialized');
      return;
    }

    try {
      _box = await Hive.openBox(_boxName);
    } catch (e) {
      DPrint.error('Failed to open RequestQueueService box: $e');
      return;
    }

    // Listen for reconnection to flush the queue
    ConnectivityService.instance.onReconnected.listen((_) {
      flushQueue();
    });
  }

  Future<void> addToQueue({
    required String method,
    required String endpoint,
    dynamic data,
  }) async {
    final request = QueuedRequest(
      method: method,
      endpoint: endpoint,
      data: data,
      timestamp: DateTime.now().toIso8601String(),
    );

    await _box.add(jsonEncode(request.toJson()));
    DPrint.info('Request queued: $method $endpoint');
  }

  Future<void> flushQueue() async {
    if (_isProcessing || _box.isEmpty) return;
    if (!ConnectivityService.instance.isConnected) return;

    _isProcessing = true;
    DPrint.info('Flushing request queue (${_box.length} items)...');

    final items = List.from(_box.values);
    final keys = List.from(_box.keys);

    for (int i = 0; i < items.length; i++) {
      final json = jsonDecode(items[i]);
      final request = QueuedRequest.fromJson(json);

      try {
        // We use a simplified call here or we can inject ApiClient
        // For the template, we'll assume ApiClient is available via Get
        final success = await _retryRequest(request);
        if (success) {
          await _box.delete(keys[i]);
          DPrint.info(
            'Queued request processed successfully: ${request.endpoint}',
          );
        }
      } catch (e) {
        DPrint.error('Failed to process queued request: $e');
        // If it's a server error (not network), we might want to discard or keep it
        // For now, we'll stop processing more items if one fails
        break;
      }
    }

    _isProcessing = false;
  }

  Future<bool> _retryRequest(QueuedRequest request) async {
    final apiClient = ApiClient(); // Singleton

    // We don't care about the return data type here since it's a background sync
    final result = await apiClient.requestGeneric(
      method: request.method,
      endpoint: request.endpoint,
      data: request.data,
    );

    return result.isRight();
  }
}
