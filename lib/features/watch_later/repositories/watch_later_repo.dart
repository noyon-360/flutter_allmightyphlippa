import '../../../core/api/network_result.dart';
import '../models/watch_later_item.dart';

abstract class WatchLaterRepo {
  /// Newest first. [playlistId] limits it to one playlist; null means all.
  NetworkResult<List<WatchLaterItem>> getWatchLater({
    String? playlistId,
    int page = 1,
    int limit = 20,
  });

  NetworkResult<WatchLaterItem> add({
    required String playlistId,
    required String videoType,
    required String videoId,
    required String title,
    String? thumbnail,
  });

  NetworkResult<WatchLaterStatus> getStatus({
    required String playlistId,
    required String videoType,
    required String videoId,
  });

  NetworkResult<void> remove(String id);
}
