import 'package:dartz/dartz.dart';
import 'package:flutter_almightyflippa/core/api/network_result.dart';
import 'package:flutter_almightyflippa/core/common/models/network_success.dart';
import 'package:flutter_almightyflippa/core/services/watch_history_service.dart';
import 'package:flutter_almightyflippa/features/video/models/video_status_model.dart';
import 'package:flutter_almightyflippa/features/video/models/video_status_request_model.dart';
import 'package:flutter_almightyflippa/features/video/models/watch_history_model.dart';
import 'package:flutter_almightyflippa/features/video/repositories/video_status_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeRepo implements VideoStatusRepo {
  final List<WatchHistoryModel> all;
  _FakeRepo(this.all);

  @override
  NetworkResult<List<WatchHistoryModel>> getWatchHistory({
    int page = 1,
    int limit = 10,
  }) async => Right(
    NetworkSuccess(
      data: all.take(limit).toList(),
      message: 'ok',
      statusCode: 200,
    ),
  );

  @override
  NetworkResult<WatchHistoryModel> updateVideoStatus(
    UpdateVideoStatusRequest request,
  ) => throw UnimplementedError();

  @override
  NetworkResult<VideoStatusModel> getVideoStatus(String videoId) =>
      throw UnimplementedError();

  @override
  NetworkResult<List<WatchHistoryModel>> getFavorites({
    int page = 1,
    int limit = 10,
  }) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  WatchHistoryModel entry(int i) => WatchHistoryModel(
    id: 'record$i',
    userId: 'user',
    videoId: '$i',
    videoType: 'movie',
  );

  late WatchHistoryService service;

  setUp(() async {
    // 25 entries: the service only keeps the first 10 loaded.
    Get.put<VideoStatusRepo>(_FakeRepo(List.generate(25, entry)));
    service = Get.put(WatchHistoryService());
    await service.getWatchHistory();
  });

  tearDown(Get.reset);

  test('finds a loaded entry by its record id, not its stream id', () async {
    expect(service.watchHistory, hasLength(10));

    final found = await service.findByRecordId('record3');

    expect(found?.videoId, '3');
    expect(await service.findByRecordId('3'), isNull);
  });

  test('finds an entry older than the loaded page', () async {
    final found = await service.findByRecordId('record20');

    expect(found?.videoId, '20');
  });

  test('returns null for an entry that no longer exists', () async {
    expect(await service.findByRecordId('gone'), isNull);
  });
}
