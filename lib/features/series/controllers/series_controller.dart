import 'package:flutter_almightyflippa/core/services/parental_lock_service.dart';
import 'package:flutter_almightyflippa/features/series/models/series_response_model.dart';
import 'package:flutter_almightyflippa/features/series/repositories/series_repo.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '../../../core/api/network_result.dart';
import '../../genre/controllers/genre_controller.dart';
import '../../genre/repo/genre_repo.dart';
import '../../playlist/models/server_request_model.dart';
import '../models/single_series_response_model.dart';

class SeriesController extends GetxController {
  final _seriesRepo = Get.find<SeriesRepo>();

  final series = <SeriesResponesModel>[].obs;
  final singleSeries = Rxn<SingleSeriesResponseModel>();

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
    getSeries();
    Get.put(GenreController(), tag: 'series').getGenres(type: ServerType.series);
    if (Get.isRegistered<ParentalLockService>()) {
      ever(ParentalLockService.to.changes, (_) => _applyParentalLock());
    }
  }

  bool _hidden(SeriesResponesModel s) => ParentalLockService.hides(
    ParentalSection.series,
    '${s.categoryId ?? ''}',
  );

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
    if (lock.isHidden(ParentalSection.series, selectedCategoryId.value)) {
      getSeries(categoryId: '');
    } else if (lock.lastChangeReveals) {
      getSeries(categoryId: selectedCategoryId.value);
    } else {
      series.removeWhere(_hidden);
    }
  }


  Future<void> getSeries({bool isLoadMore = false, String? categoryId}) async {
    if (isLoading.value || isMoreLoading.value) return;
    if (isLoadMore && !hasMore.value) return;

    if (categoryId != null) {
      selectedCategoryId.value = categoryId;
    }

    if (isLoadMore) {
      isMoreLoading.value = true;
    } else {
      isLoading.value = true;
      errorMessage.value = null;
      _currentPage = 1;
      hasMore.value = true;
    }



    final response = await (selectedCategoryId.value.isNotEmpty
        ? Get.find<GenreRepo>().getGenresById<SeriesResponesModel>(
            id: selectedCategoryId.value,
            type: ServerType.series,
            page: _currentPage,
            limit: _limit,
          )
        : _seriesRepo.getSeries(
            page: _currentPage,
            limit: _limit,
          ));

    response.fold(
      (fail) {
        DPrint.error('Error fetching series: ${fail.message}');
        errorMessage.value = fail.message;
      },
      (success) {
        errorMessage.value = null;
        if (success.data.length < _limit) {
          hasMore.value = false;
        }
        final data = success.data.where((s) => !_hidden(s)).toList();
        if (isLoadMore) {
          // Xtream's catalog ordering isn't guaranteed stable across
          // separate paginated requests, so a later page can return an
          // item already present from an earlier one. Drop repeats instead
          // of rendering the same series twice in the list.
          final existingIds = series.map((s) => s.seriesId).toSet();
          series.addAll(data.where((s) => !existingIds.contains(s.seriesId)));
        } else {
          series.assignAll(data);
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

  Future<void> getSeriesDetails({required int streamId}) async {
    if (isLoading.value) return;

    isLoading.value = true;

    final response = await _seriesRepo.getSeriesDetails(streamId: streamId);

    response.fold(
      (fail) {
        DPrint.error('Error fetching series details: ${fail.message}');
      },
      (success) {
        final data = success.data;
        singleSeries.value = data;
      },
    );

    isLoading.value = false;
  }
}
