import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/services/auth_storage_service.dart';
import '../models/epg_program_model.dart';
import '../repositories/epg_repository.dart';

/// Per-channel, per-day cache for the EPG timeline screen.
///
/// Mirrors [LiveTvNowPlayingCache]'s discipline: EPG data on Xtream is only
/// available one channel at a time, so showing a scrollable grid of channels
/// means one request per visible channel per day. Callers should only call
/// [ensureLoaded] for rows actually built by a `ListView.builder` (i.e. from
/// a row widget's `initState`), never for a whole category up front.
///
/// A day's schedule is immutable once fetched — there's no TTL/refresh here.
/// Whether a program reads as past/current/future is derived live from
/// `DateTime.now()` at render time, not from refetching this cache.
class EpgTimelineCache extends GetxService {
  final EpgRepository _repo = EpgRepository();
  final AuthStorageService _storage = AuthStorageService();

  static final _dayKeyFormat = DateFormat('yyyy-MM-dd');

  /// "$streamId|yyyy-MM-dd" -> that day's programs, or [] if fetched but
  /// empty/failed — either way, [ensureLoaded] won't retry it.
  final RxMap<String, List<EpgProgramModel>> dayPrograms =
      <String, List<EpgProgramModel>>{}.obs;

  final Set<String> _fetched = {};
  final Set<String> _inFlight = {};

  String _keyFor(int streamId, DateTime day) =>
      '$streamId|${_dayKeyFormat.format(day)}';

  List<EpgProgramModel> peek(int streamId, DateTime day) =>
      dayPrograms[_keyFor(streamId, day)] ?? const [];

  // Reads the reactive map (not the plain `_fetched` set) so widgets
  // watching this inside an Obx rebuild correctly when a fetch completes.
  bool isLoaded(int streamId, DateTime day) =>
      dayPrograms.containsKey(_keyFor(streamId, day));

  /// The 3 calendar days ([referenceDay] plus the day before and after) —
  /// enough to always have at least 10 previous and 10 next programs
  /// available around any point in [referenceDay], even close to midnight.
  List<DateTime> _daysAround(DateTime referenceDay) {
    final start = DateTime(referenceDay.year, referenceDay.month, referenceDay.day);
    return [
      start.subtract(const Duration(days: 1)),
      start,
      start.add(const Duration(days: 1)),
    ];
  }

  Future<void> ensureLoadedAround(int streamId, DateTime referenceDay) {
    return Future.wait(
      _daysAround(referenceDay).map((day) => ensureLoaded(streamId, day)),
    );
  }

  bool isLoadedAround(int streamId, DateTime referenceDay) =>
      _daysAround(referenceDay).every((day) => isLoaded(streamId, day));

  /// Every cached program for [streamId] across the day before, the day of,
  /// and the day after [referenceDay], merged and sorted by start time.
  /// Only reflects days already fetched via [ensureLoadedAround] — call
  /// that first (e.g. in `initState`).
  List<EpgProgramModel> peekAround(int streamId, DateTime referenceDay) {
    final merged = <EpgProgramModel>[
      for (final day in _daysAround(referenceDay)) ...peek(streamId, day),
    ];
    merged.sort((a, b) => a.startTime.compareTo(b.startTime));
    return merged;
  }

  Future<void> ensureLoaded(int streamId, DateTime day) async {
    final key = _keyFor(streamId, day);
    if (_fetched.contains(key) || _inFlight.contains(key)) return;
    _inFlight.add(key);

    try {
      final playlist = await _storage.getPlaylistData();
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final result = await _repo.getChannelSchedule(
        serverUrl: playlist.url,
        username: playlist.username,
        password: playlist.password,
        streamId: streamId,
        from: dayStart,
        to: dayEnd,
      );

      result.fold(
        (fail) => dayPrograms[key] = const [],
        (success) => dayPrograms[key] = success.data,
      );
    } catch (_) {
      dayPrograms[key] = const [];
    } finally {
      _fetched.add(key);
      _inFlight.remove(key);
    }
  }
}
