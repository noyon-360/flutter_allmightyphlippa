import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/constants/app_colors.dart';
import 'package:flutter_almightyflippa/features/bottom_nav/controllers/bottom_nav_controller.dart';
import 'package:flutter_almightyflippa/features/home/controllers/announcement_controller.dart';
import 'package:flutter_almightyflippa/features/home/controllers/home_controller.dart';
import 'package:flutter_almightyflippa/features/home/widgets/announcement_card.dart';
import 'package:flutter_almightyflippa/features/movie/controllers/movie_controller.dart';
import 'package:flutter_almightyflippa/features/series/controllers/series_controller.dart';
import 'package:flutter_almightyflippa/features/video/screens/live_video_play_screen.dart';
import 'package:flutter_almightyflippa/features/video/screens/video_play_screen.dart';
import 'package:get/get.dart';

import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/utils/tv_device.dart';
import '../../../core/services/watch_history_service.dart';
import '../../history/screens/history_screen.dart';
import '../../history/services/episode_series_store.dart';
import '../../history/utils/open_watch_history_item.dart';
import '../utils/continue_watching.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../../playlist/models/server_request_model.dart';
import 'package:flutter_almightyflippa/core/constants/assest_const.dart'
    hide Icons;

import '../../profile/controller/profile_controller.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final homeCtrl = Get.put(HomeController());
  final announcementCtrl = Get.put(AnnouncementController());
  final movieCtrl = Get.find<MovieController>();
  final seriesCtrl = Get.find<SeriesController>();
  final profileCtrl = Get.put(ProfileController());
  final watchHistoryService = Get.find<WatchHistoryService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: RefreshIndicator.adaptive(
        onRefresh: () => homeCtrl.refreshData(),
        color: AppColors.red,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          // Clear of the floating nav bar.
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              _buildContinueWatching(),
              const SizedBox(height: 20),
              _buildSectionHeader(context, 'Popular Movies', () {
                Get.find<BottomNavController>().changeIndex(2);
              }),
              _buildMovieList(),
              const SizedBox(height: 20),
              _buildSectionHeader(context, 'Popular Series', () {
                Get.find<BottomNavController>().changeIndex(3);
              }),
              _buildSeriesList(),
              // _buildLiveTvHistorySection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Keeps the first item per (case-insensitive) name, in order. Items
  /// without a name are always kept — they can't be told apart by name.
  static List<T> _uniqueByName<T>(List<T> items, String Function(T) nameOf) {
    final seen = <String>{};
    return [
      for (final item in items)
        if (nameOf(item).trim().isEmpty ||
            seen.add(nameOf(item).trim().toLowerCase()))
          item,
    ];
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // On TV the navigation rail already shows the logo.
              if (TvDevice.isTv)
                const SizedBox.shrink()
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    AssetsConstants.images.logo,
                    height: 45,
                    width: 45,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.flash_on, color: Colors.amber, size: 40),
                  ),
                ),
              const NotificationBell(),
            ],
          ),
          // Replaces the old "Hello <name>, Welcome to LABBY app" line with
          // something worth the space: the current announcement (new version,
          // feature, maintenance notice...) from LABBY, if there is one.
          Obx(() {
            final announcement = announcementCtrl.current;
            if (announcement == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: AnnouncementCard(
                announcement: announcement,
                onDismiss: () => announcementCtrl.dismiss(announcement),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onSeeAll,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.palette.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          TvFocusWrapper(
            onTap: onSeeAll,
            child: Text(
              'See All',
              style: TextStyle(color: context.palette.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Hidden when there's nothing to resume. Reads the shared history list,
  /// so progress saved while playing shows up as soon as the player closes.
  Widget _buildContinueWatching() {
    return Obx(() {
      final entries = continueWatchingEntries(
        watchHistoryService.watchHistory,
        EpisodeSeriesStore.seriesIdFor,
      );
      if (entries.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSectionHeader(context, 'Continue Watching', () {
            Get.to(() => const HistoryScreen());
          }),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: entries.length,
              itemBuilder: (context, index) =>
                  _buildContinueWatchingCard(entries[index]),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildContinueWatchingCard(ContinueWatchingEntry entry) {
    final item = entry.item;
    final season = item.seasonNumber;
    final episode = item.episodeNumber;
    final subtitle = !entry.isEpisode
        ? 'Movie'
        : (season != null && episode != null)
        ? 'S$season E$episode'
        : 'Series';

    return TvFocusWrapper(
      onTap: () => openWatchHistoryItem(item),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.thumbnail.isNotEmpty
                        ? Image.network(
                            item.thumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: LinearProgressIndicator(
                        value: entry.progress,
                        minHeight: 4,
                        backgroundColor: Colors.black54,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name ?? '',
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieList() {
    return Obx(() {
      if (movieCtrl.isLoading.value && movieCtrl.movies.isEmpty) {
        return _buildShimmerList();
      }

      // The provider files the same film under several categories (separate
      // stream IDs), so the same title can repeat — show it once here.
      final movies = _uniqueByName(movieCtrl.movies, (m) => m.name);

      if (movies.isEmpty) {
        return SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'No movies available',
              style: TextStyle(color: context.palette.textSecondary),
            ),
          ),
        );
      }

      return SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];
            return TvFocusWrapper(
              onTap: () {
                Get.to(
                  () => VideoPlayScreen(
                    streamId: movie.streamId,
                    type: ServerType.movies,
                    autoPlay: true,
                  ),
                );
              },
              child: Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: movie.streamIcon.isNotEmpty
                            ? Image.network(
                                movie.streamIcon,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.name,
                      style: TextStyle(
                        color: context.palette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Movie',
                      style: TextStyle(
                        color: context.palette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildSeriesList() {
    return Obx(() {
      if (seriesCtrl.isLoading.value && seriesCtrl.series.isEmpty) {
        return _buildShimmerList();
      }

      final seriesList = _uniqueByName(
        seriesCtrl.series,
        (s) => s.name ?? '',
      );

      if (seriesList.isEmpty) {
        return SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'No series available',
              style: TextStyle(color: context.palette.textSecondary),
            ),
          ),
        );
      }

      return SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: seriesList.length,
          itemBuilder: (context, index) {
            final series = seriesList[index];
            return TvFocusWrapper(
              onTap: () {
                if (series.seriesId != null) {
                  Get.to(
                    () => VideoPlayScreen(
                      streamId: series.seriesId!,
                      type: ServerType.series,
                      autoPlay: false,
                    ),
                  );
                }
              },
              child: Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: series.cover.isNotEmpty
                            ? Image.network(
                                series.cover,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      series.name ?? '',
                      style: TextStyle(
                        color: context.palette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Series',
                      style: TextStyle(
                        color: context.palette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // Widget _buildLiveTvHistorySection() {
  //   return Obx(() {
  //     final liveHistory = watchHistoryService.watchHistory
  //         .where((item) => item.videoType.toLowerCase() == 'live')
  //         .toList();

  //     // Purely a "recently watched" convenience shelf — hide it entirely
  //     // rather than showing an empty section for users with no live history.
  //     if (liveHistory.isEmpty) return const SizedBox.shrink();

  //     return Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const SizedBox(height: 20),
  //         _buildSectionHeader(context, 'Live TV History', () {
  //           Get.to(() => const HistoryScreen());
  //         }),
  //         SizedBox(
  //           height: 150,
  //           child: ListView.builder(
  //             scrollDirection: Axis.horizontal,
  //             padding: const EdgeInsets.symmetric(horizontal: 16),
  //             itemCount: liveHistory.length,
  //             itemBuilder: (context, index) {
  //               final channel = liveHistory[index];
  //               final streamId = int.tryParse(channel.videoId) ?? 0;
  //               return TvFocusWrapper(
  //                 onTap: () {
  //                   Get.to(
  //                     () => LiveVideoPlayScreen(
  //                       streamId: streamId,
  //                       channelName: channel.name ?? 'Live TV',
  //                       channelLogo: channel.thumbnail,
  //                     ),
  //                   );
  //                 },
  //                 child: Container(
  //                   width: 140,
  //                   margin: const EdgeInsets.only(right: 12),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Expanded(
  //                         child: ClipRRect(
  //                           borderRadius: BorderRadius.circular(12),
  //                           child: channel.thumbnail.isNotEmpty
  //                               ? Image.network(
  //                                   channel.thumbnail,
  //                                   fit: BoxFit.cover,
  //                                   errorBuilder: (context, error, stackTrace) =>
  //                                       _buildPlaceholder(),
  //                                 )
  //                               : _buildPlaceholder(),
  //                         ),
  //                       ),
  //                       const SizedBox(height: 8),
  //                       Text(
  //                         channel.name ?? 'Live TV',
  //                         style: const TextStyle(
  //                           color: context.palette.textPrimary,
  //                           fontSize: 14,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                         maxLines: 1,
  //                         overflow: TextOverflow.ellipsis,
  //                       ),
  //                       const Text(
  //                         'Live TV',
  //                         style: TextStyle(
  //                           color: context.palette.textSecondary,
  //                           fontSize: 12,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               );
  //             },
  //           ),
  //         ),
  //       ],
  //     );
  //   });
  // }

  Widget _buildShimmerList() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.palette.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 100,
                  decoration: BoxDecoration(
                    color: context.palette.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 60,
                  decoration: BoxDecoration(
                    color: context.palette.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: context.palette.surface,
      child: Center(
        child: Icon(Icons.movie, color: context.palette.textPrimary, size: 40),
      ),
    );
  }
}
