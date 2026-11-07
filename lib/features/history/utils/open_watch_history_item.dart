import 'package:get/get.dart';

import '../../playlist/models/server_request_model.dart';
import '../../video/models/watch_history_model.dart';
import '../../video/screens/live_video_play_screen.dart';
import '../../video/screens/video_play_screen.dart';
import '../services/episode_series_store.dart';

/// Opens the player for a watch history entry. Playback resumes from the saved
/// position, which the player loads itself.
void openWatchHistoryItem(WatchHistoryModel item) {
  // Try to parse streamId, default to 0 if fails
  final streamId = int.tryParse(item.videoId) ?? 0;
  final videoType = item.videoType.toLowerCase();

  if (videoType == 'live') {
    Get.to(
      () => LiveVideoPlayScreen(
        streamId: streamId,
        channelName: item.name ?? 'Live TV',
        channelLogo: item.thumbnail,
      ),
    );
    return;
  }

  // A series entry's videoId is the episode id. If this device knows its
  // series, open the show at that episode.
  if (videoType == 'series') {
    final seriesId = EpisodeSeriesStore.seriesIdFor(item.videoId);
    if (seriesId != null) {
      Get.to(
        () => VideoPlayScreen(
          streamId: seriesId,
          type: ServerType.series,
          resumeEpisodeId: item.videoId,
        ),
      );
      return;
    }
  }

  final type = videoType == 'series' ? ServerType.series : ServerType.movies;

  Get.to(() => VideoPlayScreen(streamId: streamId, type: type));
}
