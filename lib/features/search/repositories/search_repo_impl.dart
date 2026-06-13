import 'package:flutter_almightyflippa/core/api/api_client.dart';
import 'package:flutter_almightyflippa/core/api/network_result.dart';
import 'package:flutter_almightyflippa/core/constants/api_constants.dart';
import 'package:flutter_almightyflippa/features/playlist/models/server_request_model.dart';
import 'package:flutter_almightyflippa/features/search/repositories/search_repo.dart';

import '../../../core/services/auth_storage_service.dart';

class SearchRepoImpl implements SearchRepo {
  final ApiClient _apiClient;
  SearchRepoImpl({required ApiClient apiClient}) : _apiClient = apiClient;
  @override
  NetworkResult<List<T>> search<T>({
    required int page,
    required int limit,
    required String query,
    required ServerType type,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final storage = AuthStorageService();

    final requestData = await ServerRequestModel.fromStorage(
      type: type,
      storage: storage,
      limit: limit,
      page: page,
      search: query,
    );

    return _apiClient.post(
      endpoint: ApiConstants.server.connectTv,
      data: requestData.toJson(),
      fromJsonT: (json) {
        if (json is List) {
          return json.map((item) => fromJson(item)).toList();
        }
        return <T>[];
      },
    );
  }
}
