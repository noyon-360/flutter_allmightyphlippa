import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '../../movie/models/movie_response_model.dart';
import '../../playlist/models/server_request_model.dart';
import '../../search/repositories/search_repo.dart';
import '../../series/models/series_response_model.dart';

/// What in the user's own playlist an actor appears in: movies and series,
/// each paged separately. Nothing outside the playlist is ever shown — the
/// cast only helps the user find titles they already have.
class ActorController extends GetxController {
  final String name;

  ActorController(this.name);

  static const _pageSize = 20;

  final _searchRepo = Get.find<SearchRepo>();

  final movies = <MoviesResponseModel>[].obs;
  final series = <SeriesResponesModel>[].obs;
  final isLoadingMovies = true.obs;
  final isLoadingSeries = true.obs;
  final hasMoreMovies = false.obs;
  final hasMoreSeries = false.obs;
  final failed = false.obs;

  int _moviePage = 1;
  int _seriesPage = 1;

  @override
  void onInit() {
    super.onInit();
    loadMovies();
    loadSeries();
  }

  Future<void> loadMovies({bool more = false}) async {
    if (more && !hasMoreMovies.value) return;
    isLoadingMovies.value = true;
    if (!more) _moviePage = 1;

    final result = await _searchRepo.search<MoviesResponseModel>(
      page: _moviePage,
      limit: _pageSize,
      query: '',
      cast: name,
      type: ServerType.movies,
      fromJson: MoviesResponseModel.fromJson,
    );
    result.fold(
      (fail) {
        DPrint.error('Actor movies error: ${fail.message}');
        failed.value = true;
      },
      (success) {
        more ? movies.addAll(success.data) : movies.assignAll(success.data);
        hasMoreMovies.value = success.data.length >= _pageSize;
        _moviePage++;
      },
    );
    isLoadingMovies.value = false;
  }

  Future<void> loadSeries({bool more = false}) async {
    if (more && !hasMoreSeries.value) return;
    isLoadingSeries.value = true;
    if (!more) _seriesPage = 1;

    final result = await _searchRepo.search<SeriesResponesModel>(
      page: _seriesPage,
      limit: _pageSize,
      query: '',
      cast: name,
      type: ServerType.series,
      fromJson: SeriesResponesModel.fromJson,
    );
    result.fold(
      (fail) {
        DPrint.error('Actor series error: ${fail.message}');
        failed.value = true;
      },
      (success) {
        more ? series.addAll(success.data) : series.assignAll(success.data);
        hasMoreSeries.value = success.data.length >= _pageSize;
        _seriesPage++;
      },
    );
    isLoadingSeries.value = false;
  }
}
