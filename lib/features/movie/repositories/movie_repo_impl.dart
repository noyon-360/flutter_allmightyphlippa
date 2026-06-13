import 'package:flutter_almightyflippa/core/api/api_client.dart';
import 'package:flutter_almightyflippa/core/api/network_result.dart';
import 'package:flutter_almightyflippa/core/constants/api_constants.dart';
import 'package:flutter_almightyflippa/features/playlist/models/server_request_model.dart';

import '../../../core/services/auth_storage_service.dart';
import '../models/movie_response_model.dart';
import '../models/single_movie_response_model.dart';
import 'movie_repo.dart';

class MovieRepoImpl implements MovieRepo {
  final ApiClient _apiClient;

  MovieRepoImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  NetworkResult<List<MoviesResponseModel>> getMovies({
    required int page,
    required int limit,
  }) async {
    final storage = AuthStorageService();
    final requestData = await ServerRequestModel.fromStorage(
      type: ServerType.movies,
      storage: storage,
      limit: limit,
      page: page,
    );

    return _apiClient.post(
      endpoint: ApiConstants.server.connectTv,
      data: requestData.toJson(),
      fromJsonT: (json) {
        if (json is List) {
          return json.map((item) => MoviesResponseModel.fromJson(item)).toList();
        }
        return <MoviesResponseModel>[];
      },
    );
  }

  @override
  NetworkResult<SingleMovieResponseModel> getMovieDetails({
    required int streamId,
  }) async {
    final storage = AuthStorageService();
    final requestData = await SingleStreamRequestModel.fromStorage(
      streamType: ServerType.movie,
      streamId: streamId,
      storage: storage,
    );

    return _apiClient.post(
      endpoint: ApiConstants.server.getPlayUrl,
      data: requestData.toJson(),
      fromJsonT: (json) => SingleMovieResponseModel.fromJson(json),
    );
  }
}