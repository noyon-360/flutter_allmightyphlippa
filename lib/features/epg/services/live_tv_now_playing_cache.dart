import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_storage_service.dart';
import '../models/epg_program_model.dart';
import '../repositories/epg_repository.dart';

/// Per-channel "what's on now" cache for Live TV EPG rows.
///
/// EPG data on Xtream is only available one channel at a time
/// (`get_short_epg&stream_id=X` — there's no bulk endpoint), so showing a
/// scrollable list of channels with live now-playing info means one request
/// per channel. To avoid hammering the IPTV provider, callers should only
/// call [ensureLoaded] for channels that are actually visible on screen
/// (e.g. from a list item's `initState`, since `ListView.builder` /
/// `GridView.builder` only build items near the viewport) — never for an
/// entire category up front. Results are cached for the lifetime of this
/// service, so scrolling back up never re-fetches.
class LiveTvNowPlayingCache extends GetxService {
  final EpgRepository _repo = EpgRepository();
  final AuthStorageService _storage = AuthStorageService();

  /// channelId -> current program, or null if fetched but nothing is airing
  /// (or the fetch failed) — either way, [ensureLoaded] won't retry it.
  final RxMap<int, EpgProgramModel?> nowPlaying = <int, EpgProgramModel?>{}.obs;

  final Set<int> _fetched = {};
  final Set<int> _inFlight = {};

  EpgProgramModel? peek(int streamId) => nowPlaying[streamId];

  Future<void> ensureLoaded(int streamId) async {
    if (_fetched.contains(streamId) || _inFlight.contains(streamId)) return;
    _inFlight.add(streamId);

    try {
      final playlist = await _storage.getPlaylistData();
      final result = await _repo.getChannelEpg(
        serverUrl: playlist.url,
        username: playlist.username,
        password: playlist.password,
        streamId: streamId,
        limit: 2,
      );

      result.fold(
        (fail) {
          nowPlaying[streamId] = null;
        },
        (success) {
          final programs = success.data;
          final current = programs.firstWhereOrNull((p) => p.isNowPlaying) ??
              programs.firstWhereOrNull((p) => !p.isFuture) ??
              programs.firstOrNull;
          nowPlaying[streamId] = current;
        },
      );
    } catch (_) {
      nowPlaying[streamId] = null;
    } finally {
      _fetched.add(streamId);
      _inFlight.remove(streamId);
    }
  }
}
