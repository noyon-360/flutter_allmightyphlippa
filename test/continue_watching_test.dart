import 'package:flutter_almightyflippa/features/history/services/episode_series_store.dart';
import 'package:flutter_almightyflippa/features/home/utils/continue_watching.dart';
import 'package:flutter_almightyflippa/features/video/models/watch_history_model.dart';
import 'package:flutter_test/flutter_test.dart';

WatchHistoryModel _item(
  String videoId,
  String type, {
  double currentTime = 120,
  double duration = 600,
  bool isCompleted = false,
}) => WatchHistoryModel(
  id: 'record-$videoId',
  userId: 'user',
  videoId: videoId,
  videoType: type,
  currentTime: currentTime,
  duration: duration,
  isCompleted: isCompleted,
);

void main() {
  group('continueWatchingEntries', () {
    final knownSeries = {'ep1': 77};
    int? lookup(String id) => knownSeries[id];

    test('keeps started, unfinished movies in history order', () {
      final entries = continueWatchingEntries([
        _item('10', 'movie'),
        _item('11', 'movie', isCompleted: true),
        _item('12', 'movie', currentTime: 0),
        _item('13', 'movie'),
      ], lookup);

      expect(entries.map((e) => e.item.videoId), ['10', '13']);
      expect(entries.every((e) => !e.isEpisode), isTrue);
    });

    test('keeps episodes only when this device knows the series', () {
      final entries = continueWatchingEntries([
        _item('ep1', 'series'),
        _item('ep2', 'series'),
      ], lookup);

      expect(entries, hasLength(1));
      expect(entries.single.seriesId, 77);
      expect(entries.single.isEpisode, isTrue);
    });

    test('leaves out live channels and bad movie ids', () {
      final entries = continueWatchingEntries([
        _item('5', 'live'),
        _item('abc', 'movie'),
      ], lookup);

      expect(entries, isEmpty);
    });

    test('progress comes from position / duration, clamped', () {
      expect(
        ContinueWatchingEntry(
          _item('1', 'movie', currentTime: 150, duration: 600),
        ).progress,
        0.25,
      );
      expect(
        ContinueWatchingEntry(
          _item('1', 'movie', currentTime: 900, duration: 600),
        ).progress,
        1.0,
      );
    });
  });

  group('EpisodeSeriesStore.withEntry', () {
    test('adds and moves an episode to the newest position', () {
      final next = EpisodeSeriesStore.withEntry({'a': 1, 'b': 2}, 'a', 3);

      expect(next.keys, ['b', 'a']);
      expect(next['a'], 3);
    });

    test('drops the oldest entries beyond the cap', () {
      final next = EpisodeSeriesStore.withEntry(
        {'a': 1, 'b': 2, 'c': 3},
        'd',
        4,
        max: 3,
      );

      expect(next.keys, ['b', 'c', 'd']);
    });
  });
}
