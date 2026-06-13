import 'package:flutter_almightyflippa/core/api/api_client.dart';
import 'package:flutter_almightyflippa/core/api/network_result.dart';
import 'package:flutter_almightyflippa/core/constants/api_constants.dart';
import 'package:flutter_almightyflippa/features/series/models/series_response_model.dart';
import 'package:flutter_almightyflippa/features/series/repositories/series_repo.dart';

import '../../../core/services/auth_storage_service.dart';
import '../../playlist/models/server_request_model.dart';
import '../models/single_series_response_model.dart';

class SeriesRepoImpl implements SeriesRepo {
  final ApiClient _apiClient;
  SeriesRepoImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  NetworkResult<List<SeriesResponesModel>> getSeries({
    required int page,
    required int limit,
  }) async {
    final storage = AuthStorageService();
    final requestData = await ServerRequestModel.fromStorage(
      type: ServerType.series,
      storage: storage,
      limit: limit,
      page: page,
    );

    return _apiClient.post(
      endpoint: ApiConstants.server.connectTv,
      data: requestData.toJson(),
      fromJsonT: (json) {
        if (json is List) {
          return json.map((item) => SeriesResponesModel.fromJson(item)).toList();
        }
        return <SeriesResponesModel>[];
      },
    );
  }

  @override
  NetworkResult<SingleSeriesResponseModel> getSeriesDetails({
    required int streamId,
  }) async {
    final storage = AuthStorageService();
    final requestData = await SingleStreamRequestModel.fromStorage(
      streamType: ServerType.series,
      streamId: streamId,
      storage: storage,
    );
    return _apiClient.post(
      endpoint: ApiConstants.server.getPlayUrl,
      data: requestData.toJson(),
      fromJsonT: (json) => SingleSeriesResponseModel.fromJson(json),
    );
  }
}
