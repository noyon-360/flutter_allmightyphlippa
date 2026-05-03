import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/common/widgets/tv_focus_wrapper.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../movie/models/movie_response_model.dart';
import '../../playlist/models/server_request_model.dart';
import '../../series/models/series_response_model.dart';
import '../../video/screens/video_play_screen.dart';

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
      subtitle = '${movie.added} | Movie | 2h 44m 31s';
      streamId = movie.streamId;
    } else if (item is SeriesResponesModel) {
      final series = item as SeriesResponesModel;
      name = series.name ?? "";
      image = series.cover;
      subtitle = '${series.episodeRunTime} | Series | 2h 44m 31s';
      streamId = series.seriesId ?? 0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TvFocusWrapper(
        onTap: () {
          Get.to(() => VideoPlayScreen(streamId: streamId, type: type));
        },
        child: Row(
          children: [
            Container(
              width: 100,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.containerBgColor,
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
                  ? const Icon(Icons.movie, color: AppColors.iconColor)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.primaryWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.primaryGray,
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
}
