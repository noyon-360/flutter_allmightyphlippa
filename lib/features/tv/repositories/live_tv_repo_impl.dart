import 'package:flutter_almightyflippa/core/api/api_client.dart';
import 'package:flutter_almightyflippa/core/constants/api_constants.dart';

import '../../../core/api/network_result.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../playlist/models/server_request_model.dart';
import '../models/live_tv_reponse_model.dart';
import '../models/single_live_tv_reponse_model.dart';
import 'live_tv_repo.dart';

class LiveTvRepoImpl implements LiveTvRepo {
  final ApiClient _apiClient;

  LiveTvRepoImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  NetworkResult<List<LiveTvModel>> getLiveTVList({
    required int page,
    required int limit,
  }) async {
    final storage = AuthStorageService();
    final requestData = await ServerRequestModel.fromStorage(
      type: ServerType.channels,
      storage: storage,
      limit: limit,
      page: page,
    );
    return _apiClient.post(
      endpoint: ApiConstants.server.connectTv,
      data: requestData.toJson(),
      fromJsonT: (json) {
        if (json is List) {
          return json.map((item) => LiveTvModel.fromJson(item)).toList();
        }
        return <LiveTvModel>[];
      },
    );
  }

  @override
  NetworkResult<SingleLiveTvResponseModel> getSingleLiveTV({
    required int streamId,
  }) async {
    final storage = AuthStorageService();
    final requestData = await SingleStreamRequestModel.fromStorage(
      streamType: ServerType.live,
      streamId: streamId,
      storage: storage,
    );

    return _apiClient.post(
      endpoint: ApiConstants.server.getPlayUrl,
      data: requestData.toJson(),
      fromJsonT: (json) => SingleLiveTvResponseModel.fromJson(json),
    );
  }
}
