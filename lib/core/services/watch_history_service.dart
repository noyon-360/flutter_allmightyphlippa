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

  Future<void> getWatchHistory() async {
    isLoading.value = true;
    final result = await _videoStatusRepo.getWatchHistory();
    result.fold(
      (failure) {
        isLoading.value = false;
      },
      (success) {
        watchHistory.assignAll(success.data);
        isLoading.value = false;
      },
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
      watchHistory[index] = newItem;
    }
  }

  void refreshList() {
    getWatchHistory();
  }
}
