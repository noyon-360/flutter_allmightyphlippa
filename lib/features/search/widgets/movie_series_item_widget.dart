import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/common/widgets/tv_focus_wrapper.dart';
import 'package:get/get.dart';
import '../../movie/models/movie_response_model.dart';
import '../../playlist/models/server_request_model.dart';
import '../../series/models/series_response_model.dart';
import '../../tv/models/live_tv_reponse_model.dart';
import '../../video/screens/live_video_play_screen.dart';
import '../../video/screens/video_play_screen.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

class MovieSeriesItemWidget extends StatelessWidget {
  final dynamic item;
  final ServerType type;

  const MovieSeriesItemWidget({
    super.key,
    required this.item,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    String name = "";
    String image = "";
    String subtitle = "";
    int streamId = 0;

    if (item is MoviesResponseModel) {
      final movie = item as MoviesResponseModel;
      name = movie.name;
      image = movie.streamIcon;
      subtitle =
          'Movie${movie.rating.isNotEmpty && movie.rating != '0' ? ' | ⭐ ${movie.rating}' : ''}';
      streamId = movie.streamId;
    } else if (item is SeriesResponesModel) {
      final series = item as SeriesResponesModel;
      name = series.name ?? "";
      image = series.cover;
      subtitle =
          'Series${series.episodeRunTime != null && series.episodeRunTime! > 0 ? ' | ~${series.episodeRunTime} min/ep' : ''}';
      streamId = series.seriesId ?? 0;
    } else if (item is LiveTvModel) {
      final channel = item as LiveTvModel;
      name = channel.name;
      image = channel.streamIcon;
      subtitle = 'Live TV';
      streamId = channel.streamId;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TvFocusWrapper(
        onTap: () {
          if (item is LiveTvModel) {
            Get.to(
              () => LiveVideoPlayScreen(
                streamId: streamId,
                channelName: name,
                channelLogo: image,
                // So the guide shows this channel's category.
                categoryId: _channelCategory(item as LiveTvModel),
              ),
            );
          } else {
            Get.to(
              () => VideoPlayScreen(
                streamId: streamId,
                type: type,
                autoPlay: type == ServerType.series ? false : true,
              ),
            );
          }
        },
        child: Row(
          children: [
            Container(
              width: 100,
              height: 80,
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(8),
                image: image.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(image),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
              ),
              child: image.isEmpty
                  ? Icon(Icons.movie, color: context.palette.textPrimary)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: context.palette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The channel's category: `category_id`, or the first of `category_ids`
  /// when the provider leaves the single field empty.
  static String? _channelCategory(LiveTvModel channel) {
    if (channel.categoryId.isNotEmpty) return channel.categoryId;
    if (channel.categoryIds.isNotEmpty) {
      return channel.categoryIds.first.toString();
    }
    return null;
  }
}

