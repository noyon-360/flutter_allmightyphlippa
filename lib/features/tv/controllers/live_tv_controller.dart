import 'package:flutter_almightyflippa/core/services/parental_lock_service.dart';
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

  /// Bumped by every fresh (non load-more) load. A response that comes back
  /// after a newer load started is stale and dropped.
  int _generation = 0;

  @override
  void onInit() {
    super.onInit();
    getLiveTvList();
    Get.put(GenreController(), tag: 'channels')
        .getGenres(type: ServerType.live);
    if (Get.isRegistered<ParentalLockService>()) {
      ever(ParentalLockService.to.changes, (_) => _applyParentalLock());
    }
  }

  bool _hidden(LiveTvModel c) =>
      ParentalLockService.hides(ParentalSection.live, c.categoryId);

  /// Applies lock changes right away: leave a category that just got
  /// locked, drop newly locked items, or reload when something was unlocked
  /// (filtered-out items can't be brought back without fetching them again).
  void _applyParentalLock() {
    // A load in flight would drop the reload/switch below (it returns early
    // while loading), so apply the change once it has finished.
    if (isLoading.value) {
      once(isLoading, (_) => _applyParentalLock());
      return;
    }
    final lock = ParentalLockService.to;
    if (lock.isHidden(ParentalSection.live, selectedCategoryId.value)) {
      getLiveTvList(categoryId: '');
    } else if (lock.lastChangeReveals) {
      getLiveTvList(categoryId: selectedCategoryId.value);
    } else {
      liveTvList.removeWhere(_hidden);
    }
  }


  Future<void> getLiveTvList({bool isLoadMore = false, String? categoryId}) async {
    if (isLoadMore) {
      if (isLoading.value || isMoreLoading.value || !hasMore.value) return;
    } else if (isLoading.value && categoryId == null) {
      // Plain refresh while something is already loading: nothing to add.
      return;
    }
    // An explicit category (a chip, or a channel opened from search) always
    // wins: it supersedes the in-flight load instead of being dropped by it
    // (e.g. the default "All" load this controller starts in onInit()).
    final generation = isLoadMore ? _generation : ++_generation;

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

    // A newer load started while this one was waiting: drop this result
    // (the newer load owns isLoading and will clear it).
    if (generation != _generation) {
      if (isLoadMore) isMoreLoading.value = false;
      return;
    }

    result.fold(
      (fail) {
        DPrint.error('Error fetching live TV list: ${fail.message}');
        errorMessage.value = fail.message;
      },
      (success) {
        errorMessage.value = null;
        if (success.data.length < _limit) {
          hasMore.value = false;
        }
        final data = success.data.where((c) => !_hidden(c)).toList();

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
