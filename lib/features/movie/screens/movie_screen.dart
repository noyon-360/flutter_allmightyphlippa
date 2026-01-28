import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/constants/app_colors.dart';
import 'package:get/get.dart';

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

  // final List<Map<String, String>> _genres = [
  //   {
  //     'name': 'Bollywood',
  //     'image': 'assets/images/bollywood.png',
  //   }, // Placeholder paths, logic only
  //   {'name': 'Hollywood', 'image': 'assets/images/hollywood.png'},
  // ];

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      movieCtrl.getMovies(isLoadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (movieCtrl.isLoading.value) {
        return _buildShimmerContent();
      }

      return Column(
        children: [
          // Search Bar - Fixed at top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(color: AppColors.hintText),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.iconColor,
                ),
                filled: true,
                fillColor: AppColors.containerBgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: AppColors.primaryWhite),
            ),
          ),

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
                  // Genres Title
                  // SliverToBoxAdapter(
                  //   child: Padding(
                  //     padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //       children: [
                  //         Text(
                  //           'Genres',
                  //           style: Theme.of(context).textTheme.titleLarge
                  //               ?.copyWith(
                  //                 color: AppColors.primaryWhite,
                  //                 fontWeight: FontWeight.bold,
                  //               ),
                  //         ),
                  //         Text(
                  //           'See All',
                  //           style: Theme.of(context).textTheme.bodyMedium
                  //               ?.copyWith(color: AppColors.primaryGray),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),

                  // Genres List
                  // SliverToBoxAdapter(
                  //   child: Container(
                  //     height: 140,
                  //     margin: const EdgeInsets.symmetric(vertical: 16),
                  //     child: ListView.builder(
                  //       scrollDirection: Axis.horizontal,
                  //       padding: const EdgeInsets.symmetric(horizontal: 16),
                  //       itemCount: _genres.length,
                  //       itemBuilder: (context, index) {
                  //         return Container(
                  //           width: 160,
                  //           margin: const EdgeInsets.only(right: 16),
                  //           decoration: BoxDecoration(
                  //             color:
                  //                 AppColors.containerBgColor, // Fallback color
                  //             borderRadius: BorderRadius.circular(12),
                  //             // Gradient or Image could go here
                  //           ),
                  //           child: Stack(
                  //             alignment: Alignment.center,
                  //             children: [
                  //               // Placeholder for genre image/gradient
                  //               Positioned(
                  //                 bottom: 10,
                  //                 child: Column(
                  //                   children: [
                  //                     Text(
                  //                       _genres[index]['name']!,
                  //                       style: const TextStyle(
                  //                         color: AppColors.primaryWhite,
                  //                         fontWeight: FontWeight.bold,
                  //                         fontSize: 16,
                  //                       ),
                  //                     ),
                  //                     const Text(
                  //                       'Lorem Ipsum',
                  //                       style: TextStyle(
                  //                         color: AppColors.primaryGray,
                  //                         fontSize: 12,
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         );
                  //       },
                  //     ),
                  //   ),
                  // ),

                  // Top Search Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Top Search',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primaryWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                        child: InkWell(
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
                                          image: NetworkImage(movie.streamIcon),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      '${movie.added} | Movie | 2h 44m 31s',
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
