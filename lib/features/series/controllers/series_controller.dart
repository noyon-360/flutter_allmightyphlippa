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
        final data = success.data;

        if (data.length < _limit) {
          hasMore.value = false;
        }
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
