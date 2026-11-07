import 'package:flutx_core/core/debug_print.dart';

import '../../../core/services/hive_storage_service.dart';

/// Watch history saves only the episode id for series (the backend has no
/// series id field), and Xtream can't look a series up from an episode. So
/// this device remembers which series each episode it played belongs to;
/// that's what lets Continue Watching reopen the show at that episode.
/// Episodes last played on another device stay unknown (same as tvOS).
class EpisodeSeriesStore {
  EpisodeSeriesStore._();

  static const _key = 'episode_series_map';
  static const maxEntries = 300;

  static Map<String, int> _read() {
    try {
      final raw = HiveStorageService().box.get(_key);
      if (raw is! Map) return {};
      return {
        for (final e in raw.entries)
          if (e.value is int) e.key.toString(): e.value as int,
      };
    } catch (e) {
      // Box not open (Hive init failed): behave as if nothing is stored.
      DPrint.error('EpisodeSeriesStore read failed: $e');
      return {};
    }
  }

  static int? seriesIdFor(String episodeId) => _read()[episodeId];

  static Future<void> remember({
    required String episodeId,
    required int seriesId,
  }) async {
    final current = _read();
    if (current[episodeId] == seriesId) return;
    try {
      await HiveStorageService().box.put(
        _key,
        withEntry(current, episodeId, seriesId),
      );
    } catch (e) {
      DPrint.error('EpisodeSeriesStore write failed: $e');
    }
  }

  /// Adds or moves [episodeId] to the newest position and drops the oldest
  /// entries beyond [max], so the map can't grow forever.
  static Map<String, int> withEntry(
    Map<String, int> current,
    String episodeId,
    int seriesId, {
    int max = maxEntries,
  }) {
    final next = Map<String, int>.of(current)
      ..remove(episodeId)
      ..[episodeId] = seriesId;
    final overflow = next.length - max;
    if (overflow > 0) {
      next.keys.take(overflow).toList().forEach(next.remove);
    }
    return next;
  }
}
