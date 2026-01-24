import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

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
  int _currentPage = 1;
  final int _limit = 10;

  @override
  void onInit() {
    super.onInit();
    getLiveTvList();
  }

  Future<void> getLiveTvList({bool isLoadMore = false}) async {
    if (isLoading.value || isMoreLoading.value) return;
    if (isLoadMore && !hasMore.value) return;

    if (isLoadMore) {
      isMoreLoading.value = true;
    } else {
      isLoading.value = true;
      _currentPage = 1;
      hasMore.value = true;
    }

    final result = await _liveTvRepo.getLiveTVList(
      page: _currentPage,
      limit: _limit,
    );

    result.fold(
      (fail) {
        DPrint.error('Error fetching live TV list: ${fail.message}');
      },
      (success) {
        final data = success.data;
        if (data.length < _limit) {
          hasMore.value = false;
        }

        if (isLoadMore) {
          liveTvList.addAll(data);
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
