import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '../../genre/controllers/genre_controller.dart';
import '../../genre/repo/genre_repo.dart';
import '../../playlist/models/server_request_model.dart';
import '../models/movie_response_model.dart';
import '../models/single_movie_response_model.dart';
import '../repositories/movie_repo.dart';
import '../../../core/api/network_result.dart';

class MovieController extends GetxController {
  final _movieRepo = Get.find<MovieRepo>();

  final movies = <MoviesResponseModel>[].obs;
  final movie = Rxn<SingleMovieResponseModel>();

  final isLoading = false.obs;
  final isMoreLoading = false.obs;
  final hasMore = true.obs;
  final selectedCategoryId = ''.obs;
  int _currentPage = 1;
  final int _limit = 10;

  @override
  void onInit() {
    super.onInit();
    getMovies();
    Get.put(GenreController(), tag: 'movies').getGenres(type: ServerType.movies);
  }

  Future<void> getMovies({bool isLoadMore = false, String? categoryId}) async {
    if (isLoading.value || isMoreLoading.value) return;
    if (isLoadMore && !hasMore.value) return;

    if (categoryId != null) {
      selectedCategoryId.value = categoryId;
    }

    if (isLoadMore) {
      isMoreLoading.value = true;
    } else {
      isLoading.value = true;
      _currentPage = 1;
      hasMore.value = true;
    }



    final result = await (selectedCategoryId.value.isNotEmpty
        ? Get.find<GenreRepo>().getGenresById<MoviesResponseModel>(
            id: selectedCategoryId.value,
            type: ServerType.movies,
          )
        : _movieRepo.getMovies(
            page: _currentPage,
            limit: _limit,
          ));

    result.fold(
      (fail) {
        DPrint.error('Error fetching movies: ${fail.message}');
      },
      (success) {
        final data = success.data;
        if (data.length < _limit) {
          hasMore.value = false;
        }

        if (isLoadMore) {
          movies.addAll(data);
        } else {
          movies.assignAll(data);
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

  Future<void> getMovieDetails({required int streamId}) async {
    isLoading.value = true;
    final result = await _movieRepo.getMovieDetails(streamId: streamId);

    isLoading.value = false;

    result.fold(
      (fail) {
        DPrint.error(
          '❌ ERROR: Fetching movie details failed for streamId: $streamId',
        );
        DPrint.error('   Message: ${fail.message}');
        DPrint.error('   Status Code: ${fail.statusCode}');
      },
      (success) {
        DPrint.info('Movie details fetched successfully');
        final data = success.data;

        movie.value = data;
      },
    );
  }
}
