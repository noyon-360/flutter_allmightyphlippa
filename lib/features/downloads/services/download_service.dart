import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/download_item.dart';

class DownloadService extends GetxService {
  static DownloadService get to => Get.find<DownloadService>();

  static const _boxName = 'downloads_box';
  late Box _box;

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(minutes: 5),
    receiveTimeout: const Duration(minutes: 60),
    // Use a large receive buffer to avoid per-byte callbacks
    headers: {'Connection': 'keep-alive'},
  ));

  final _cancelTokens = <String, CancelToken>{};
  // Last time onProgress was called per download ID (throttle to 500ms)
  final _lastNotify = <String, DateTime>{};

  Future<DownloadService> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }
    // Mark interrupted downloads as failed
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw != null) {
        final item = DownloadItem.fromMap(raw as Map);
        if (item.status == DownloadStatus.downloading) {
          item.status = DownloadStatus.failed;
          item.progress = 0.0;
          await _save(item);
        }
      }
    }
    return this;
  }

  // ─── Read ────────────────────────────────────────────────────────────────

  List<DownloadItem> getAll() {
    return _box.keys
        .map((k) => DownloadItem.fromMap(_box.get(k) as Map))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  DownloadItem? getById(String id) {
    final raw = _box.get(id);
    return raw == null ? null : DownloadItem.fromMap(raw as Map);
  }

  bool hasCompleted(String videoId, String videoType) {
    final id = _buildId(videoId, videoType);
    final item = getById(id);
    return item?.isCompleted == true && File(item!.localPath).existsSync();
  }

  String? localPath(String videoId, String videoType) {
    if (!hasCompleted(videoId, videoType)) return null;
    return getById(_buildId(videoId, videoType))?.localPath;
  }

  // ─── Write / Control ─────────────────────────────────────────────────────

  Future<DownloadItem> startDownload({
    required String videoId,
    required String videoType,
    required String title,
    required String url,
    required String ext,
    String? thumbnail,
    required void Function(DownloadItem item, bool isStatusChange) onProgress,
  }) async {
    final id = _buildId(videoId, videoType);

    final existing = getById(id);
    if (existing != null && existing.isCompleted) return existing;
    if (existing != null && existing.isDownloading) return existing;

    final dir = await _downloadsDir();
    final path = '${dir.path}/$id.$ext';

    final item = DownloadItem(
      id: id,
      videoId: videoId,
      videoType: videoType,
      title: title,
      thumbnail: thumbnail,
      url: url,
      localPath: path,
      ext: ext,
      status: DownloadStatus.downloading,
    );
    // Only write to Hive on status changes, not progress ticks
    await _save(item);
    onProgress(item, true);

    final cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;

    _dio.download(
      url,
      path,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          item.progress = received / total;
          item.fileSize = total;
        }
        // Throttle UI updates to at most once every 500ms
        final now = DateTime.now();
        final last = _lastNotify[id];
        if (last == null || now.difference(last).inMilliseconds >= 500) {
          _lastNotify[id] = now;
          onProgress(item, false); // not a status change — don't reload
        }
      },
    ).then((_) async {
      item.status = DownloadStatus.completed;
      item.progress = 1.0;
      await _save(item);
      _cancelTokens.remove(id);
      _lastNotify.remove(id);
      onProgress(item, true); // status change — trigger reload
    }).catchError((e) async {
      item.status = DownloadStatus.failed;
      item.progress = 0.0;
      if (kDebugMode && !(e is DioException && CancelToken.isCancel(e))) {
        debugPrint('Download error for $id: $e');
      }
      await _save(item);
      _cancelTokens.remove(id);
      _lastNotify.remove(id);
      onProgress(item, true); // status change — trigger reload
    });

    return item;
  }

  Future<void> cancelDownload(String id) async {
    _cancelTokens[id]?.cancel('User cancelled');
    _cancelTokens.remove(id);
    _lastNotify.remove(id);
    final item = getById(id);
    if (item != null) {
      item.status = DownloadStatus.failed;
      item.progress = 0.0;
      await _save(item);
      try { File(item.localPath).deleteSync(); } catch (_) {}
    }
  }

  Future<void> deleteDownload(String id) async {
    await cancelDownload(id);
    final item = getById(id);
    if (item != null) {
      try { File(item.localPath).deleteSync(); } catch (_) {}
    }
    await _box.delete(id);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Future<void> _save(DownloadItem item) => _box.put(item.id, item.toMap());

  static String _buildId(String videoId, String videoType) =>
      '${videoType}_$videoId';

  Future<Directory> _downloadsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/labbytv_downloads');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  String formatFileSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
