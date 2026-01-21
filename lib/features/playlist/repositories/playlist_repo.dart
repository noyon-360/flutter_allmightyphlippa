import 'package:flutter_almightyflippa/core/api/network_result.dart';
import '../models/playlist_model.dart';

abstract class PlaylistRepo {
  NetworkResult<void> addPlaylist(PlaylistModel playlist);
  NetworkResult<List<PlaylistModel>> getPlaylists();
  NetworkResult<void> deletePlaylist(String id);
}
