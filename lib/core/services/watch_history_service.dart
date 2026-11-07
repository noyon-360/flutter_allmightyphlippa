import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import '../../features/video/models/watch_history_model.dart';
import '../../features/video/repositories/video_status_repo.dart';

class WatchHistoryService extends GetxService {
  final _videoStatusRepo = Get.find<VideoStatusRepo>();

  final watchHistory = <WatchHistoryModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    getWatchHistory();
  }

  /// Background triggers (position ticks, post-dispose sync callbacks) can land
  /// while Flutter is mid-frame, e.g. during a route's pop transition. Mutating
  /// an .obs in that window crashes the watching Obx with "widget tree was
  /// locked". Defer to the next frame in that case; mutate immediately otherwise
  /// so normal user-triggered refreshes stay instant.
  void _safeMutate(VoidCallback mutate) {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle ||
        SchedulerBinding.instance.schedulerPhase == SchedulerPhase.postFrameCallbacks) {
      mutate();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => mutate());
    }
  }

  Future<void> getWatchHistory() async {
    _safeMutate(() => isLoading.value = true);
    // 30, not the repo default of 10: Home's Continue Watching row filters
    // out live and finished entries, so it needs more to choose from.
    final result = await _videoStatusRepo.getWatchHistory(limit: 30);
    result.fold(
      (failure) {
        _safeMutate(() => isLoading.value = false);
      },
      (success) {
        _safeMutate(() {
          watchHistory.assignAll(success.data);
          isLoading.value = false;
        });
      },
    );
  }

  /// Finds an entry by its record id (`_id`), which is what a continue
  /// watching push calls `videoId`. It can be older than the page held in
  /// [watchHistory], so anything not loaded is looked up with a bigger fetch.
  Future<WatchHistoryModel?> findByRecordId(String id) async {
    final loaded = watchHistory.firstWhereOrNull((item) => item.id == id);
    if (loaded != null) return loaded;

    final result = await _videoStatusRepo.getWatchHistory(limit: 100);
    return result.fold(
      (failure) => null,
      (success) => success.data.firstWhereOrNull((item) => item.id == id),
    );
  }

  void updateProgressGlobally({
    required String videoId,
    required double newTime,
    required double duration,
  }) {
    final index = watchHistory.indexWhere((item) => item.videoId == videoId);
    if (index != -1) {
      final oldItem = watchHistory[index];
      final newItem = WatchHistoryModel(
        id: oldItem.id,
        userId: oldItem.userId,
        videoId: oldItem.videoId,
        videoType: oldItem.videoType,
        seasonNumber: oldItem.seasonNumber,
        episodeNumber: oldItem.episodeNumber,
        name: oldItem.name,
        currentTime: newTime,
        thumbnail: oldItem.thumbnail,
        duration: duration,
        progressPercentage: duration > 0 ? (newTime / duration) * 100 : 0,
        isCompleted: oldItem.isCompleted,
        isLoved: oldItem.isLoved,
        lastWatchedAt: DateTime.now(),
      );
      _safeMutate(() => watchHistory[index] = newItem);
    }
  }

  void refreshList() {
    getWatchHistory();
  }
}
