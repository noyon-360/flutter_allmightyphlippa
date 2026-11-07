import '../../video/models/watch_history_model.dart';

/// A watch history entry the Home "Continue Watching" row can resume.
class ContinueWatchingEntry {
  final WatchHistoryModel item;

  /// Series id for an episode, null for a movie.
  final int? seriesId;

  const ContinueWatchingEntry(this.item, {this.seriesId});

  bool get isEpisode => seriesId != null;

  double get progress {
    final value = item.duration > 0
        ? item.currentTime / item.duration
        : item.progressPercentage / 100;
    return value.clamp(0.0, 1.0);
  }
}

/// Same rules as the tvOS Home: started but unfinished movies, plus episodes
/// whose series this device knows ([seriesIdFor]). Live channels are left out.
List<ContinueWatchingEntry> continueWatchingEntries(
  List<WatchHistoryModel> history,
  int? Function(String episodeId) seriesIdFor,
) {
  final entries = <ContinueWatchingEntry>[];
  for (final item in history) {
    if (item.isCompleted || item.currentTime <= 0) continue;
    switch (item.videoType.toLowerCase()) {
      case 'movie':
        if (int.tryParse(item.videoId) == null) continue;
        entries.add(ContinueWatchingEntry(item));
      case 'series':
        final seriesId = seriesIdFor(item.videoId);
        if (seriesId == null) continue;
        entries.add(ContinueWatchingEntry(item, seriesId: seriesId));
    }
  }
  return entries;
}
