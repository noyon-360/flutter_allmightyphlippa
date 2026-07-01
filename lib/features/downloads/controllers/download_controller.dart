import 'package:flutter_almightyflippa/core/services/premium_service.dart';
import 'package:get/get.dart';

import '../models/download_item.dart';
import '../services/download_service.dart';

class DownloadController extends GetxController {
  static DownloadController get to => Get.find<DownloadController>();

  late final DownloadService _service;

  final items = <DownloadItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    _service = DownloadService.to;
    _reload();
  }

  // Full reload from Hive — only called on init, cancel, delete, status changes
  void _reload() => items.assignAll(_service.getAll());

  // Update a single item in-place — called on every progress tick (no Hive read)
  void _updateInPlace(DownloadItem updated) {
    final idx = items.indexWhere((i) => i.id == updated.id);
    if (idx >= 0) {
      items[idx] = updated;
    } else {
      items.insert(0, updated);
    }
  }

  bool isDownloaded(String videoId, String videoType) =>
      _service.hasCompleted(videoId, videoType);

  bool isDownloading(String videoId, String videoType) {
    final id = '${videoType}_$videoId';
    return items.any((i) => i.id == id && i.isDownloading);
  }

  double progressOf(String videoId, String videoType) {
    final id = '${videoType}_$videoId';
    return items.firstWhereOrNull((i) => i.id == id)?.progress ?? 0.0;
  }

  String? localPath(String videoId, String videoType) =>
      _service.localPath(videoId, videoType);

  Future<void> download({
    required String videoId,
    required String videoType,
    required String title,
    required String url,
    required String ext,
    String? thumbnail,
  }) async {
    if (!PremiumService.to.check) {
      Get.snackbar('Premium Required', 'Offline downloads are available for premium subscribers.');
      return;
    }

    await _service.startDownload(
      videoId: videoId,
      videoType: videoType,
      title: title,
      url: url,
      ext: ext,
      thumbnail: thumbnail,
      onProgress: (item, isStatusChange) {
        if (isStatusChange) {
          // Re-read from Hive so the persisted state is reflected
          _reload();
        } else {
          // Just update this item's progress in the list — no Hive read
          _updateInPlace(item);
        }
      },
    );
  }

  Future<void> cancel(String videoId, String videoType) async {
    await _service.cancelDownload('${videoType}_$videoId');
    _reload();
  }

  Future<void> delete(String videoId, String videoType) async {
    await _service.deleteDownload('${videoType}_$videoId');
    _reload();
  }
}
