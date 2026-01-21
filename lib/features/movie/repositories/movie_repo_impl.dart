import 'package:flutter_almightyflippa/core/api/api_client.dart';
import 'package:flutter_almightyflippa/core/api/network_result.dart';
import 'package:flutter_almightyflippa/core/constants/api_constants.dart';
import 'package:flutter_almightyflippa/features/playlist/models/movie_series_channel_request_model.dart';

import '../../../core/services/auth_storage_service.dart';
import '../models/movie_response_model.dart';
import 'movie_repo.dart';

class MovieRepoImpl implements MovieRepo {
  final ApiClient _apiClient;

  MovieRepoImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  NetworkResult<List<MovieResponseModel>> getMovies() async {
    final storage = AuthStorageService();
    final requestData = await ServerRequestModel.fromStorage(
      type: ServerType.movies,
      storage: storage,
      limit: 2,
      page: 1,
    );

    return _apiClient.post(
      endpoint: ApiConstants.server.connectTv,
      data: requestData.toJson(),
      fromJsonT: (json) => (json as List)
          .map((item) => MovieResponseModel.fromJson(item))
          .toList(),
    );
  }
}
