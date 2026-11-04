import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../playlist/models/server_request_model.dart';
import '../../search/widgets/movie_series_item_widget.dart';
import '../controllers/actor_controller.dart';
import '../services/cast_photo_service.dart';
import '../widgets/actor_avatar.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

/// Movies and series in the user's playlist featuring one actor.
class ActorScreen extends StatelessWidget {
  final String name;

  const ActorScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    // One controller per actor, so opening a second actor from here (or the
    // same one later) never mixes their results.
    final ctrl = Get.put(ActorController(name), tag: name);
    CastPhotoService.to.ensureLoaded([name]);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Obx(() {
        final loading =
            ctrl.isLoadingMovies.value || ctrl.isLoadingSeries.value;
        final hasAny = ctrl.movies.isNotEmpty || ctrl.series.isNotEmpty;

        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  ActorAvatar(name: name, size: 84),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: context.palette.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'In your playlist',
                          style: TextStyle(
                            color: context.palette.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (loading && !hasAny)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.red),
                ),
              )
            else if (!hasAny)
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
                child: Text(
                  ctrl.failed.value
                      ? "Couldn't load titles right now. Please try again."
                      : 'No movies or series with $name in your playlist.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.palette.textSecondary,
                    fontSize: 15,
                  ),
                ),
              )
            else ...[
              if (ctrl.movies.isNotEmpty) ...[
                _sectionTitle(context, 'Movies'),
                for (final movie in ctrl.movies)
                  MovieSeriesItemWidget(item: movie, type: ServerType.movies),
                if (ctrl.hasMoreMovies.value)
                  _loadMore(() => ctrl.loadMovies(more: true)),
              ],
              if (ctrl.series.isNotEmpty) ...[
                _sectionTitle(context, 'Series'),
                for (final show in ctrl.series)
                  MovieSeriesItemWidget(item: show, type: ServerType.series),
                if (ctrl.hasMoreSeries.value)
                  _loadMore(() => ctrl.loadSeries(more: true)),
              ],
            ],
          ],
        );
      }),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
    child: Text(
      title,
      style: TextStyle(
        color: context.palette.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _loadMore(VoidCallback onTap) => Center(
    child: TextButton(
      onPressed: onTap,
      child: const Text('Show more', style: TextStyle(color: AppColors.red)),
    ),
  );
}
