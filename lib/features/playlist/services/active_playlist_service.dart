import 'package:get/get.dart';

import '../../../core/services/auth_storage_service.dart';
import '../models/playlist_model.dart';
import '../repositories/playlist_repo.dart';

/// Works out the backend id of the playlist the app is currently using.
///
/// The active playlist is stored as bare credentials, and installs from before
/// ids were stored (or a playlist that was just added) have no id. Those are
/// matched against the cached playlist list first, then the network, and the
/// id found is saved so the lookup only happens once.
class ActivePlaylistService {
  ActivePlaylistService({AuthStorageService? storage, PlaylistRepo? repo})
    : _storage = storage ?? AuthStorageService(),
      _repo = repo;

  final AuthStorageService _storage;
  final PlaylistRepo? _repo;

  PlaylistRepo get _playlistRepo => _repo ?? Get.find<PlaylistRepo>();

  Future<String?> activePlaylistId() async {
    final data = await _storage.getPlaylistData();
    if (data.isEmpty) return null;
    if (data.id != null) return data.id;

    final cached = (await _storage.getPlaylists())
        .map(PlaylistModel.fromJson)
        .toList();
    var id = data.matchIdIn(cached);

    if (id == null) {
      final result = await _playlistRepo.getPlaylists();
      id = result.fold((_) => null, (s) => data.matchIdIn(s.data));
    }

    if (id != null) await _storage.savePlaylistData(data.copyWith(id: id));
    return id;
  }
}
