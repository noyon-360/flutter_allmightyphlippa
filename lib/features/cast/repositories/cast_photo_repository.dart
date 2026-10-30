import '../../../core/api/api_client.dart';
import '../../../core/api/network_result.dart';
import '../../../core/constants/api_constants.dart';

class CastPhotoRepository {
  final ApiClient _apiClient = ApiClient();

  /// Photo URL for each actor (null when none is known). Names are matched
  /// on the server, which owns the photo source key.
  NetworkResult<Map<String, String?>> getPhotos(List<String> names) async {
    return await _apiClient.get(
      endpoint: ApiConstants.cast.photos,
      queryParameters: {'names': names.join(',')},
      fromJsonT: (json) {
        if (json is Map) {
          return {
            for (final entry in json.entries)
              entry.key.toString(): entry.value?.toString(),
          };
        }
        return <String, String?>{};
      },
    );
  }
}
