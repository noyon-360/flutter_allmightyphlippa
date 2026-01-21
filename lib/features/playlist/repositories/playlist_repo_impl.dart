import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../core/api/network_result.dart';
import '../models/playlist_model.dart';
import 'playlist_repo.dart';

class PlaylistRepoImpl implements PlaylistRepo {
  final ApiClient _apiClient = ApiClient();

  @override
  NetworkResult<void> addPlaylist(
    PlaylistModel playlist,
  ) async {
    return _apiClient.post<void>(
      endpoint: ApiConstants.playlist.addPlaylist,
      data: playlist.toJson(),
      fromJsonT: (json) => {},
    );
  }

  @override
  NetworkResult<List<PlaylistModel>> getPlaylists() async {
    return _apiClient.get<List<PlaylistModel>>(
      endpoint: ApiConstants.playlist.getPlaylist,
      fromJsonT: (json) {
        if (json is List) {
          return json.map((e) => PlaylistModel.fromJson(e)).toList();
        }
        return [];
      },
    );
  }

  @override
  NetworkResult<void> deletePlaylist(
    String id,
  ) async {
    return _apiClient.delete<void>(
      endpoint: ApiConstants.playlist.deletePlaylist(id),
      fromJsonT: (json) => {},
    );
  }
}
