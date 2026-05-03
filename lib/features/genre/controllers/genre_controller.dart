import 'package:flutter_almightyflippa/features/genre/models/genre_model.dart';
import 'package:flutter_almightyflippa/features/genre/repo/genre_repo.dart';
import 'package:flutter_almightyflippa/features/tv/models/live_tv_reponse_model.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '../../movie/models/movie_response_model.dart';
import '../../playlist/models/server_request_model.dart';
import '../../series/models/series_response_model.dart';

class GenreController extends GetxController {
  final _genreRepo = Get.find<GenreRepo>();

  final genres = <GenreModel>[].obs;
  final isLoading = false.obs;

  Future<void> getGenres({required ServerType type}) async {
    isLoading.value = true;
    final result = await _genreRepo.getGenres(type);
    isLoading.value = false;
    result.fold(
      (fail) {
        DPrint.error('Error fetching genres: ${fail.message}');
      },
      (success) {
        final data = success.data;
        genres.assignAll(data);
      },
    );
  }

  Future<void> getGenresById({
    required String id,
    required ServerType type,
  }) async {
    isLoading.value = true;
    final result = await _genreRepo.getGenresById(id: id, type: type);
    isLoading.value = false;
    result.fold(
      (fail) {
        DPrint.error('Error fetching genres: ${fail.message}');
      },
      (success) {
        final data = success.data;
        if (type == ServerType.series) {
          final series = data as SeriesResponesModel;
        }

        if (type == ServerType.movies || type == ServerType.movie) {
          final movies = data as MoviesResponseModel;
        }

        if (type == ServerType.live) {
          final liveTv = data as LiveTvModel;
        }
      },
    );
  }
}
