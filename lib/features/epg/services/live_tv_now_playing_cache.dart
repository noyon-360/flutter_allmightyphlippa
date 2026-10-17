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

  /// Channels whose fetch failed rather than returning an empty schedule.
  /// Both land as a null in [nowPlaying], but they mean different things to
  /// the viewer, so the row needs to be able to tell them apart.
  final RxSet<int> failedChannels = <int>{}.obs;

  final Set<int> _fetched = {};
  final Set<int> _inFlight = {};


  /// After [clear], fetches for the next couple of minutes ask the backend to
  /// skip its own EPG cache too, so "Update EPG" really returns fresh data.
  DateTime? _bypassServerCacheUntil;
  bool get _bypassServerCache =>
      _bypassServerCacheUntil?.isAfter(DateTime.now()) ?? false;

  /// Drops everything cached so visible rows/channels refetch on next build.
  void clear() {
    nowPlaying.clear();
    failedChannels.clear();
    _fetched.clear();
    _inFlight.clear();
    _bypassServerCacheUntil = DateTime.now().add(const Duration(minutes: 2));
  }

  EpgProgramModel? peek(int streamId) => nowPlaying[streamId];

  /// Whether this channel's guide failed to load, as opposed to loading fine
  /// and having nothing scheduled.
  bool hasFailed(int streamId) => failedChannels.contains(streamId);

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
        refresh: _bypassServerCache,
      );

      result.fold(
        (fail) {
          failedChannels.add(streamId);
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
      failedChannels.add(streamId);
      nowPlaying[streamId] = null;
    } finally {
      _fetched.add(streamId);
      _inFlight.remove(streamId);
    }
  }
}
