import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '../../../core/api/network_result.dart';
import '../../genre/controllers/genre_controller.dart';
import '../../genre/repo/genre_repo.dart';
import '../../playlist/models/server_request_model.dart';
import '../models/live_tv_reponse_model.dart';
import '../models/single_live_tv_reponse_model.dart';
import '../repositories/live_tv_repo.dart';

class LiveTvController extends GetxController {
  final _liveTvRepo = Get.find<LiveTvRepo>();

  final liveTvList = <LiveTvModel>[].obs;
  final singleLiveTv = Rxn<SingleLiveTvResponseModel>();

  final isLoading = false.obs;
  final isMoreLoading = false.obs;
  final hasMore = true.obs;
  final selectedCategoryId = ''.obs;
  final errorMessage = Rxn<String>();
  int _currentPage = 1;
  final int _limit = 10;

  @override
  void onInit() {
    super.onInit();
    getLiveTvList();
    Get.put(GenreController(), tag: 'channels')
        .getGenres(type: ServerType.live);
  }

  Future<void> getLiveTvList({bool isLoadMore = false, String? categoryId}) async {
    if (isLoading.value || isMoreLoading.value) return;
    if (isLoadMore && !hasMore.value) return;

    if (categoryId != null) {
      selectedCategoryId.value = categoryId;
    }

    if (isLoadMore) {
      isMoreLoading.value = true;
    } else {
      liveTvList.clear();
      isLoading.value = true;
      errorMessage.value = null;
      _currentPage = 1;
      hasMore.value = true;
    }



    final result = await (selectedCategoryId.value.isNotEmpty
        ? Get.find<GenreRepo>().getGenresById<LiveTvModel>(
            id: selectedCategoryId.value,
            type: ServerType.live,
            page: _currentPage,
            limit: _limit,
          )
        : _liveTvRepo.getLiveTVList(
            page: _currentPage,
            limit: _limit,
          ));

    result.fold(
      (fail) {
        DPrint.error('Error fetching live TV list: ${fail.message}');
        errorMessage.value = fail.message;
      },
      (success) {
        errorMessage.value = null;
        final data = success.data;
        if (data.length < _limit) {
          hasMore.value = false;
        }

        if (isLoadMore) {
          // Xtream's catalog ordering isn't guaranteed stable across
          // separate paginated requests, so a later page can return a
          // channel already present from an earlier one. Drop repeats
          // instead of rendering the same channel twice in the list.
          final existingIds = liveTvList.map((c) => c.streamId).toSet();
          liveTvList.addAll(
            data.where((c) => !existingIds.contains(c.streamId)),
          );
        } else {
          liveTvList.assignAll(data);
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

  Future<void> getSingleLiveTv({required int id}) async {
    if (isLoading.value) return;
    isLoading.value = true;

    final result = await _liveTvRepo.getSingleLiveTV(streamId: id);

    result.fold(
      (fail) {
        DPrint.error('Error fetching single live TV: ${fail.message}');
      },
      (success) {
        singleLiveTv.value = success.data;
      },
    );

    isLoading.value = false;
  }
}
