import 'package:flutter_almightyflippa/core/api/api_client.dart';
import 'package:flutter_almightyflippa/core/api/network_result.dart';
import 'package:flutter_almightyflippa/core/constants/api_constants.dart';
import 'package:flutter_almightyflippa/features/genre/models/genre_model.dart';
import 'package:flutter_almightyflippa/features/genre/repo/genre_repo.dart';
import 'package:flutter_almightyflippa/features/series/models/series_response_model.dart';

import '../../../core/services/auth_storage_service.dart';
import '../../movie/models/movie_response_model.dart';
import '../../playlist/models/server_request_model.dart';
import '../../tv/models/live_tv_reponse_model.dart';

class GenreRepoImpl implements GenreRepo {
  final ApiClient _apiClient;
  GenreRepoImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  NetworkResult<List<GenreModel>> getGenres(ServerType type) async {
    final storage = AuthStorageService();
    final requestData = await ServerRequestModel.fromStorage(
      type: type,
      storage: storage,
    );
    return _apiClient.post(
      endpoint: ApiConstants.genre.getCategories,
      data: requestData.toJson(),
      fromJsonT: (json) =>
          (json as List).map((item) => GenreModel.fromJson(item)).toList(),
    );
  }

  @override
  NetworkResult<List<T>> getGenresById<T>({
    required String id,
    required ServerType type,
  }) async {
    final storage = AuthStorageService();
    final requestData = await ServerRequestModel.fromStorage(
      type: type,
      storage: storage,
    );
    return _apiClient.post(
      endpoint: ApiConstants.genre.getCategoriesByType(id),
      data: requestData.toJson(),
      fromJsonT: (json) {
        if (type == ServerType.series) {
          return SeriesResponesModel.fromJson(json) as List<T>;
        } else if (type == ServerType.movies || type == ServerType.movie) {
          return MoviesResponseModel.fromJson(json) as List<T>;
        } else if (type == ServerType.live || type == ServerType.channels) {
          return LiveTvModel.fromJson(json) as List<T>;
        }
        return GenreModel.fromJson(json) as List<T>;
      },
    );
  }
}
