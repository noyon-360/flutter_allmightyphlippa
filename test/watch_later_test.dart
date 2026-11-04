import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_almightyflippa/core/api/network_result.dart';
import 'package:flutter_almightyflippa/core/common/models/network_failure.dart';
import 'package:flutter_almightyflippa/core/common/models/network_success.dart';
import 'package:flutter_almightyflippa/features/playlist/models/playlist_data.dart';
import 'package:flutter_almightyflippa/features/playlist/models/playlist_model.dart';
import 'package:flutter_almightyflippa/features/playlist/models/server_request_model.dart';
import 'package:flutter_almightyflippa/features/watch_later/controllers/watch_later_controller.dart';
import 'package:flutter_almightyflippa/features/watch_later/models/watch_later_item.dart';
import 'package:flutter_almightyflippa/features/watch_later/repositories/watch_later_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

WatchLaterItem item(String id, {String? playlistId = 'p1'}) => WatchLaterItem(
  id: id,
  videoType: 'movie',
  videoId: id,
  title: 'Title $id',
  thumbnail: '',
  playlistId: playlistId,
);

class _FakeRepo implements WatchLaterRepo {
  _FakeRepo(this.pages);

  /// Pages returned in order, one per call.
  final List<List<WatchLaterItem>> pages;
  final calls = <String?>[];
  final removed = <String>[];

  /// When set, list calls wait on it, to simulate a slow response.
  Completer<void>? gate;

  @override
  NetworkResult<List<WatchLaterItem>> getWatchLater({
    String? playlistId,
    int page = 1,
    int limit = 20,
  }) async {
    calls.add(playlistId);
    final g = gate;
    if (g != null) await g.future;
    final data = pages.isEmpty ? <WatchLaterItem>[] : pages.removeAt(0);
    return Right(NetworkSuccess(data: data, message: 'ok', statusCode: 200));
  }

  @override
  NetworkResult<void> remove(String id) async {
    removed.add(id);
    return Right(NetworkSuccess(data: null, message: 'ok', statusCode: 200));
  }

  @override
  NetworkResult<WatchLaterItem> add({
    required String playlistId,
    required String videoType,
    required String videoId,
    required String title,
    String? thumbnail,
  }) => throw UnimplementedError();

  @override
  NetworkResult<WatchLaterStatus> getStatus({
    required String playlistId,
    required String videoType,
    required String videoId,
  }) => throw UnimplementedError();
}

class _FailingRepo extends _FakeRepo {
  _FailingRepo() : super([]);

  @override
  NetworkResult<List<WatchLaterItem>> getWatchLater({
    String? playlistId,
    int page = 1,
    int limit = 20,
  }) async => const Left(ConnectionFailure(message: 'offline'));
}

void main() {
  group('WatchLaterItem.fromJson', () {
    test('reads a populated playlist', () {
      final i = WatchLaterItem.fromJson({
        '_id': 'w1',
        'videoType': 'series',
        'videoId': '42',
        'title': 'Show',
        'thumbnail': 'http://x/c.jpg',
        'playlist': {'_id': 'p1', 'name': 'Home'},
        'createdAt': '2026-11-04T10:00:00.000Z',
      });
      expect(i.id, 'w1');
      expect(i.isSeries, isTrue);
      expect(i.serverType, ServerType.series);
      expect(i.streamId, 42);
      expect(i.playlistId, 'p1');
      expect(i.playlistName, 'Home');
      expect(i.createdAt, DateTime.utc(2026, 11, 4, 10));
    });

    test('reads a bare playlist id and a missing playlist', () {
      final bare = WatchLaterItem.fromJson({
        '_id': 'w2',
        'videoType': 'movie',
        'videoId': '7',
        'playlist': 'p2',
      });
      expect(bare.playlistId, 'p2');
      expect(bare.playlistName, isNull);
      expect(bare.serverType, ServerType.movies);

      final gone = WatchLaterItem.fromJson({
        '_id': 'w3',
        'videoType': 'movie',
        'videoId': '7',
        'playlist': null,
      });
      expect(gone.playlistId, isNull);
    });

    test('status parses saved and not saved', () {
      final saved = WatchLaterStatus.fromJson({'isSaved': true, 'id': 'w1'});
      expect(saved.isSaved, isTrue);
      expect(saved.id, 'w1');
      final not = WatchLaterStatus.fromJson({'isSaved': false, 'id': null});
      expect(not.isSaved, isFalse);
      expect(not.id, isNull);
    });
  });

  group('PlaylistData id', () {
    test('old stored data without an id still loads', () {
      final d = PlaylistData.fromJson({
        'url': 'http://a',
        'username': 'u',
        'password': 'p',
      });
      expect(d.id, isNull);
      expect(d.toJson().containsKey('id'), isFalse);
      expect(PlaylistData.fromJson(d.copyWith(id: 'p1').toJson()).id, 'p1');
    });

    test('matchIdIn prefers the stored id, else matches credentials', () {
      final playlists = [
        PlaylistModel(id: 'p1', url: 'http://a', userName: 'u', password: 'x'),
        PlaylistModel(id: 'p2', url: 'http://a', userName: 'u', password: 'p'),
      ];
      final noId = PlaylistData(url: 'http://a', username: 'u', password: 'p');
      expect(noId.matchIdIn(playlists), 'p2');
      expect(noId.copyWith(id: 'p1').matchIdIn(playlists), 'p1');
      // A stored id for a playlist that's gone falls back to credentials.
      expect(noId.copyWith(id: 'deleted').matchIdIn(playlists), 'p2');
      expect(
        PlaylistData(url: 'http://b', username: 'u', password: 'p')
            .matchIdIn(playlists),
        isNull,
      );
      expect(PlaylistData.empty().matchIdIn(playlists), isNull);
    });
  });

  test('resolveAction', () {
    expect(
      WatchLaterController.resolveAction(item('a'), 'p1'),
      WatchLaterOpenAction.play,
    );
    expect(
      WatchLaterController.resolveAction(item('a', playlistId: 'p2'), 'p1'),
      WatchLaterOpenAction.otherPlaylist,
    );
    expect(
      WatchLaterController.resolveAction(item('a'), null),
      WatchLaterOpenAction.otherPlaylist,
    );
    expect(
      WatchLaterController.resolveAction(item('a', playlistId: null), 'p1'),
      WatchLaterOpenAction.playlistGone,
    );
  });

  group('WatchLaterController', () {
    setUp(() => Get.testMode = true);
    tearDown(Get.reset);

    WatchLaterController make(_FakeRepo repo, {String? activeId = 'p1'}) =>
        WatchLaterController(
          repo: repo,
          resolveActivePlaylistId: () async => activeId,
        );

    test('"This playlist" asks for the active playlist only', () async {
      final repo = _FakeRepo([
        [item('a')],
      ]);
      final c = make(repo);
      await c.load();
      expect(repo.calls, ['p1']);
      expect(c.items.map((e) => e.id), ['a']);
      expect(c.hasMore.value, isFalse);
    });

    test('"All playlists" sends no playlist filter', () async {
      final repo = _FakeRepo([
        [item('a')],
        [item('a'), item('b', playlistId: 'p2')],
      ]);
      final c = make(repo);
      await c.load();
      c.setScope(WatchLaterScope.all);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(repo.calls, ['p1', null]);
      expect(c.items.map((e) => e.id), ['a', 'b']);
    });

    test('without an active playlist "This playlist" is empty', () async {
      final repo = _FakeRepo([
        [item('a')],
      ]);
      final c = make(repo, activeId: null);
      await c.load();
      expect(repo.calls, isEmpty);
      expect(c.items, isEmpty);
      expect(c.isLoading.value, isFalse);
    });

    test('load more skips items already in the list', () async {
      final full = List.generate(
        WatchLaterController.pageSize,
        (i) => item('i$i'),
      );
      final repo = _FakeRepo([
        full,
        [item('i19'), item('next')],
      ]);
      final c = make(repo);
      await c.load();
      await c.load(isLoadMore: true);
      expect(c.items, hasLength(WatchLaterController.pageSize + 1));
      expect(c.items.last.id, 'next');
      expect(c.isMoreLoading.value, isFalse);
    });

    test('a slow response for the old tab is dropped', () async {
      final repo = _FakeRepo([
        [item('old')],
        [item('new', playlistId: 'p2')],
      ]);
      final c = make(repo);
      repo.gate = Completer<void>();
      final first = c.load();
      await Future<void>.delayed(Duration.zero);
      c.setScope(WatchLaterScope.all);
      await Future<void>.delayed(Duration.zero);
      repo.gate!.complete();
      await first;
      await Future<void>.delayed(Duration.zero);
      // Both calls were answered in order, but only the newer one counts.
      expect(c.scope.value, WatchLaterScope.all);
      expect(c.items.map((e) => e.id), ['new']);
      expect(c.isLoading.value, isFalse);
    });

    test('a failed load shows an error', () async {
      final c = make(_FailingRepo());
      await c.load();
      expect(c.errorMessage.value, 'offline');
      expect(c.items, isEmpty);
    });

    test('remove takes the item out and calls the backend', () async {
      final repo = _FakeRepo([
        [item('a'), item('b')],
      ]);
      final c = make(repo);
      await c.load();
      expect(await c.remove(c.items.first), isTrue);
      expect(repo.removed, ['a']);
      expect(c.items.map((e) => e.id), ['b']);
    });
  });
}
