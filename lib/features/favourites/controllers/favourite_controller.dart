import 'package:get/get.dart';
import '../../video/repositories/video_status_repo.dart';
import '../../video/models/watch_history_model.dart';
import '../../video/models/video_status_request_model.dart';

class FavouriteController extends GetxController {
  final VideoStatusRepo _videoStatusRepo = Get.find<VideoStatusRepo>();

  final favourites = <WatchHistoryModel>[].obs;
  final isLoading = false.obs;
  final isMoreLoading = false.obs;
  final hasMore = true.obs;

  int _currentPage = 1;
  final int _limit = 10;

  @override
  void onInit() {
    super.onInit();
    getFavourites();
  }

  Future<void> getFavourites({bool isLoadMore = false}) async {
    if (isLoading.value || isMoreLoading.value) return;
    if (isLoadMore && !hasMore.value) return;

    if (isLoadMore) {
      isMoreLoading.value = true;
    } else {
      isLoading.value = true;
      _currentPage = 1;
      hasMore.value = true;
    }

    final result = await _videoStatusRepo.getFavorites(
      page: _currentPage,
      limit: _limit,
    );

    result.fold(
      (fail) {
        // Handle error
        Get.snackbar('Error', fail.message);
      },
      (success) {
        final data = success.data;
        if (data.length < _limit) {
          hasMore.value = false;
        }

        if (isLoadMore) {
          favourites.addAll(data);
        } else {
          favourites.assignAll(data);
        }
        _currentPage++;
      },
    );

    if (isLoadMore) {
      isMoreLoading.value = false;
    } else {
      isLoading.value = false;
    }
  }

  Future<void> removeFavourite(WatchHistoryModel item) async {
    final result = await _videoStatusRepo.updateVideoStatus(
      UpdateVideoStatusRequest(
        title: item.name ?? 'Unknown Title',
        videoId: item.videoId,
        videoType: item.videoType,
        isLoved: false,
      ),
    );

    result.fold(
      (fail) => Get.snackbar('Error', 'Failed to remove from favourites'),
      (success) {
        favourites.removeWhere((element) => element.videoId == item.videoId);
        Get.snackbar('Success', 'Removed from favourites');
      },
    );
  }
}
