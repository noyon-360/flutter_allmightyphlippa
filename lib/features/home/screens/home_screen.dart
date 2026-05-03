import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/constants/app_colors.dart';
import 'package:flutter_almightyflippa/features/bottom_nav/controllers/bottom_nav_controller.dart';
import 'package:flutter_almightyflippa/features/home/controllers/home_controller.dart';
import 'package:flutter_almightyflippa/features/movie/controllers/movie_controller.dart';
import 'package:flutter_almightyflippa/features/series/controllers/series_controller.dart';
import 'package:flutter_almightyflippa/features/video/screens/video_play_screen.dart';
import 'package:get/get.dart';

import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../playlist/models/server_request_model.dart';
import 'package:flutter_almightyflippa/core/constants/assest_const.dart'
    hide Icons;

import '../../profile/controller/profile_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final homeCtrl = Get.put(HomeController());
  final movieCtrl = Get.find<MovieController>();
  final seriesCtrl = Get.find<SeriesController>();
  final profileCtrl = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: RefreshIndicator.adaptive(
        onRefresh: () => homeCtrl.refreshData(),
        color: AppColors.red,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
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
              // IconButton(
              //   onPressed: () {},
              //   icon: const Icon(
              //     Icons.notifications_none_outlined,
              //     color: AppColors.primaryWhite,
              //     size: 28,
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() {
            if (profileCtrl.isLoading.value) {
              return Container(
                height: 24,
                width: 250,
                decoration: BoxDecoration(
                  color: AppColors.primaryGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }
            // Get first name for "Hello Ross" style if possible, or just use full name as requested "Hello Ross" (assuming name is Ross)
            // The request image shows "Hello Ross, Welcome to LABBY app"
            // I'll just use the full name for now.
            final name = profileCtrl.userProfile.value?.name ?? "Guest";
            return Text(
              'Hello $name, Welcome to LABBY app',
              style: const TextStyle(
                color: AppColors.primaryWhite,
                fontSize: 18,
                fontWeight: FontWeight.w400,
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
            style: const TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          TvFocusWrapper(
            onTap: onSeeAll,
            child: const Text(
              'See All',
              style: TextStyle(color: AppColors.primaryGray, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieList() {
    return Obx(() {
      if (movieCtrl.isLoading.value && movieCtrl.movies.isEmpty) {
        return _buildShimmerList();
      }

      if (movieCtrl.movies.isEmpty) {
        return const SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'No movies available',
              style: TextStyle(color: AppColors.primaryGray),
            ),
          ),
        );
      }

      return SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: movieCtrl.movies.length,
          itemBuilder: (context, index) {
            final movie = movieCtrl.movies[index];
            return TvFocusWrapper(
              onTap: () {
                Get.to(
                  () => VideoPlayScreen(
                    streamId: movie.streamId,
                    type: ServerType.movies,
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
                      style: const TextStyle(
                        color: AppColors.primaryWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Movie',
                      style: const TextStyle(
                        color: AppColors.primaryGray,
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

      if (seriesCtrl.series.isEmpty) {
        return const SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'No series available',
              style: TextStyle(color: AppColors.primaryGray),
            ),
          ),
        );
      }

      return SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: seriesCtrl.series.length,
          itemBuilder: (context, index) {
            final series = seriesCtrl.series[index];
            return TvFocusWrapper(
              onTap: () {
                if (series.seriesId != null) {
                  Get.to(
                    () => VideoPlayScreen(
                      streamId: series.seriesId!,
                      type: ServerType.series,
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
                      style: const TextStyle(
                        color: AppColors.primaryWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Series',
                      style: const TextStyle(
                        color: AppColors.primaryGray,
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
                      color: AppColors.containerBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.containerBgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 60,
                  decoration: BoxDecoration(
                    color: AppColors.containerBgColor,
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
      color: AppColors.containerBgColor,
      child: const Center(
        child: Icon(Icons.movie, color: AppColors.iconColor, size: 40),
      ),
    );
  }
}
