import 'package:flutter_almightyflippa/core/api/network_result.dart';
import '../models/playlist_model.dart';

abstract class PlaylistRepo {
  NetworkResult<void> addPlaylist(PlaylistModel playlist);
  NetworkResult<List<PlaylistModel>> getPlaylists();
  NetworkResult<void> deletePlaylist(String id);

  /// Updates the playlist identified by [PlaylistModel.id] in place, so
  /// anything tied to it (favourites, history) keeps pointing at it.
  NetworkResult<void> updatePlaylist(PlaylistModel playlist);
}
