import 'package:flutter_almightyflippa/features/tv/models/live_tv_reponse_model.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '../../movie/models/movie_response_model.dart';
import '../../series/models/series_response_model.dart';
import '../../playlist/models/server_request_model.dart';
import '../repositories/search_repo.dart';

class SearchState {
  final query = ''.obs;
  final results = <dynamic>[].obs;
  final isLoading = false.obs;
  final isMoreLoading = false.obs;
  final hasMore = true.obs;
  final hasSearched = false.obs;
  int currentPage = 1;

  void clear() {
    results.clear();
    hasMore.value = true;
    hasSearched.value = false;
    currentPage = 1;
  }
}

class SearchingController extends GetxController {
  final _searchRepo = Get.find<SearchRepo>();
  final int _limit = 10;

  final Map<ServerType, SearchState> _states = {
    ServerType.movies: SearchState(),
    ServerType.series: SearchState(),
    ServerType.channels: SearchState(),
  };

  SearchState getState(ServerType type) => _states[type] ??= SearchState();

  void onQueryChanged(String val, ServerType type) {
    final state = getState(type);
    state.query.value = val;
    state.hasSearched.value = false;
    if (val.isEmpty) {
      state.clear();
    }
  }

  Future<void> searchData({
    required ServerType type,
    bool isLoadMore = false,
  }) async {
    final state = getState(type);

    if (state.query.value.isEmpty) return;
    if (state.isLoading.value || state.isMoreLoading.value) return;
    if (isLoadMore && !state.hasMore.value) return;

    if (isLoadMore) {
      state.isMoreLoading.value = true;
    } else {
      state.isLoading.value = true;
      state.currentPage = 1;
      state.hasMore.value = true;
      state.results.clear();
    }

    final response = await _searchRepo.search(
      page: state.currentPage,
      limit: _limit,
      query: state.query.value,
      type: type,
      fromJson: (json) {
        if (type == ServerType.movies) {
          return MoviesResponseModel.fromJson(json);
        } else if (type == ServerType.series) {
          return SeriesResponesModel.fromJson(json);
        } else if (type == ServerType.channels) {
          return LiveTvModel.fromJson(json);
        }
      },
    );

    response.fold(
      (failure) {
        DPrint.error('Search error: ${failure.message}');
        if (!isLoadMore) {
          state.results.clear();
          state.hasSearched.value = true;
        }
      },
      (success) {
        final data = success.data;
        if (data.length < _limit) {
          state.hasMore.value = false;
        }

        if (isLoadMore) {
          state.results.addAll(data);
        } else {
          state.results.assignAll(data);
          state.hasSearched.value = true;
        }
        state.currentPage++;
      },
    );

    if (isLoadMore) {
      state.isMoreLoading.value = false;
    } else {
      state.isLoading.value = false;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
