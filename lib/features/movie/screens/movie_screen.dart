import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/constants/app_colors.dart';
import 'package:flutter_almightyflippa/core/common/widgets/tv_focus_wrapper.dart';
import 'package:get/get.dart';

import 'package:flutter_almightyflippa/features/search/widgets/search_section_widget.dart';
import '../../genre/controllers/genre_controller.dart';
import '../../genre/screens/category_selection_screen.dart';
import '../../playlist/models/server_request_model.dart';
import '../../video/screens/video_play_screen.dart';
import '../controllers/movie_controller.dart';

class MovieScreen extends StatefulWidget {
  const MovieScreen({super.key});

  @override
  State<MovieScreen> createState() => _MovieScreenState();
}

class _MovieScreenState extends State<MovieScreen> {
  final movieCtrl = Get.put(MovieController());
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  final genreCtrl = Get.find<GenreController>(tag: 'movies');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Scroll to Top visibility
    if (_scrollController.offset >= 400 && !_showBackToTop) {
      setState(() {
        _showBackToTop = true;
      });
    } else if (_scrollController.offset < 400 && _showBackToTop) {
      setState(() {
        _showBackToTop = false;
      });
    }

    // Load more
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      movieCtrl.getMovies(isLoadMore: true);
    }
  }

  void _showAllCategories(BuildContext context) {
    Get.to(
      () => CategorySelectionScreen(
        title: 'Movie Categories',
        genreTag: 'movies',
        selectedCategoryId: movieCtrl.selectedCategoryId,
        onCategorySelected: (categoryId) {
          movieCtrl.getMovies(categoryId: categoryId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (movieCtrl.isLoading.value) {
        return _buildShimmerContent();
      }

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const SearchSectionWidget(type: ServerType.movies),

            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: () async {
                  await movieCtrl.getMovies();
                },
                color: AppColors.red,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ),

                    // Categories Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Categories',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppColors.primaryWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (genreCtrl.genres.length > 8)
                              GestureDetector(
                                onTap: () => _showAllCategories(context),
                                child: const Text(
                                  'See All',
                                  style: TextStyle(
                                    color: AppColors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Genres List
                    SliverToBoxAdapter(
                      child: Container(
                        height: 35,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount:
                              (genreCtrl.genres.length > 8
                                  ? 8
                                  : genreCtrl.genres.length) +
                              1,
                          itemBuilder: (context, index) {
                            final isAll = index == 0;
                            final genre = isAll
                                ? null
                                : genreCtrl.genres[index - 1];
                            final categoryId = isAll ? '' : genre!.categoryId;
                            final categoryName = isAll
                                ? 'All'
                                : genre!.categoryName;

                            return Obx(() {
                              final isSelected =
                                  movieCtrl.selectedCategoryId.value ==
                                  categoryId;

                              return GestureDetector(
                                onTap: () {
                                  movieCtrl.getMovies(categoryId: categoryId);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.red
                                        : AppColors.containerBgColor,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.red
                                          : AppColors.primaryWhite.withOpacity(
                                              0.1,
                                            ),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    categoryName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.primaryWhite
                                          : AppColors.primaryGray,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            });
                          },
                        ),
                      ),
                    ),

                    // Results Title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Obx(() {
                          String title = 'All Movies';
                          if (movieCtrl.selectedCategoryId.value.isNotEmpty) {
                            final genre = genreCtrl.genres.firstWhereOrNull(
                              (g) =>
                                  g.categoryId ==
                                  movieCtrl.selectedCategoryId.value,
                            );
                            title = genre?.categoryName ?? 'Movies';
                          }

                          return Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppColors.primaryWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                          );
                        }),
                      ),
                    ),

                    // Movie List
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final movie = movieCtrl.movies[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: TvFocusWrapper(
                            onTap: () {
                              Get.to(
                                () => VideoPlayScreen(
                                  streamId: movie.streamId,
                                  type: ServerType.movies,
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 100,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.containerBgColor,
                                    borderRadius: BorderRadius.circular(8),
                                    image: movie.streamIcon.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              movie.streamIcon,
                                            ),
                                            fit: BoxFit.cover,
                                            onError: (_, __) {},
                                          )
                                        : null,
                                  ),
                                  child: movie.streamIcon.isEmpty
                                      ? const Icon(
                                          Icons.movie,
                                          color: AppColors.iconColor,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        movie.name,
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
                                        // Formatting date and duration if available, else placeholder
                                        '${movie.added} | Movie',
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
                      }, childCount: movieCtrl.movies.length),
                    ),

                    // Loading Indicator for Pagination
                    if (movieCtrl.isMoreLoading.value)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.red,
                            ),
                          ),
                        ),
                      ),

                    const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _showBackToTop
            ? FloatingActionButton(
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                backgroundColor: AppColors.red,
                mini: true,
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              )
            : null,
      );
    });
  }

  Widget _buildShimmerContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.containerBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 24,
            width: 100,
            decoration: BoxDecoration(
              color: AppColors.containerBgColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) => Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppColors.containerBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 24,
            width: 120,
            decoration: BoxDecoration(
              color: AppColors.containerBgColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.containerBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.containerBgColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            width: 150,
                            decoration: BoxDecoration(
                              color: AppColors.containerBgColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
