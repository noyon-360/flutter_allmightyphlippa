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
      fromJsonT: (json) {
        if (json is List) {
          return json.map((item) => GenreModel.fromJson(item)).toList();
        }
        return <GenreModel>[];
      },
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
        if (json is! List) return <T>[];
        final List list = json;
        if (type == ServerType.series) {
          return list.map((item) => SeriesResponesModel.fromJson(item)).toList()
              as List<T>;
        } else if (type == ServerType.movies || type == ServerType.movie) {
          return list.map((item) => MoviesResponseModel.fromJson(item)).toList()
              as List<T>;
        } else if (type == ServerType.live || type == ServerType.channels) {
          return list.map((item) => LiveTvModel.fromJson(item)).toList()
              as List<T>;
        }
        return list.map((item) => GenreModel.fromJson(item)).toList()
            as List<T>;
      },
    );
  }
}
