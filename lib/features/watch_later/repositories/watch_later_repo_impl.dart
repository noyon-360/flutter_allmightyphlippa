import '../../../core/api/api_client.dart';
import '../../../core/api/network_result.dart';
import '../../../core/constants/api_constants.dart';
import '../models/watch_later_item.dart';
import 'watch_later_repo.dart';

class WatchLaterRepoImpl implements WatchLaterRepo {
  final ApiClient _apiClient;

  WatchLaterRepoImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  NetworkResult<List<WatchLaterItem>> getWatchLater({
    String? playlistId,
    int page = 1,
    int limit = 20,
  }) {
    return _apiClient.get(
      endpoint: ApiConstants.watchLater.list,
      queryParameters: {
        'page': page,
        'limit': limit,
        'playlistId': ?playlistId,
      },
      fromJsonT: (json) => ((json['items'] as List?) ?? const [])
          .map((e) => WatchLaterItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  @override
  NetworkResult<WatchLaterItem> add({
    required String playlistId,
    required String videoType,
    required String videoId,
    required String title,
    String? thumbnail,
  }) {
    return _apiClient.post(
      endpoint: ApiConstants.watchLater.add,
      data: {
        'playlistId': playlistId,
        'videoType': videoType,
        'videoId': videoId,
        'title': title,
        'thumbnail': ?thumbnail,
      },
      fromJsonT: (json) =>
          WatchLaterItem.fromJson(Map<String, dynamic>.from(json)),
    );
  }

  @override
  NetworkResult<WatchLaterStatus> getStatus({
    required String playlistId,
    required String videoType,
    required String videoId,
  }) {
    return _apiClient.get(
      endpoint: ApiConstants.watchLater.status,
      queryParameters: {
        'playlistId': playlistId,
        'videoType': videoType,
        'videoId': videoId,
      },
      fromJsonT: (json) =>
          WatchLaterStatus.fromJson(Map<String, dynamic>.from(json)),
    );
  }

  @override
  NetworkResult<void> remove(String id) {
    return _apiClient.delete<void>(
      endpoint: ApiConstants.watchLater.remove(id),
      fromJsonT: (_) {},
    );
  }
}
