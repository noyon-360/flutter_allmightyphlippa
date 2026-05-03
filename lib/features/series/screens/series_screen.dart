import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/features/search/widgets/search_section_widget.dart';
import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../playlist/models/server_request_model.dart';
import '../../video/screens/video_play_screen.dart';
import 'package:flutter_almightyflippa/features/series/controllers/series_controller.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  final seriesCtrl = Get.put(SeriesController());
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

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
      seriesCtrl.getSeries(isLoadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (seriesCtrl.isLoading.value) {
        return _buildShimmerContent();
      }

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const SearchSectionWidget(type: ServerType.series),

            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: () async {
                  await seriesCtrl.getSeries();
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

                    // // Genres List
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.primaryWhite,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),

                    // Movie List
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final series = seriesCtrl.series[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: TvFocusWrapper(
                            onTap: () {
                              Get.to(
                                () => VideoPlayScreen(
                                  streamId: series.seriesId!,
                                  type: ServerType.series,
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
                                    image: series.cover.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(series.cover),
                                            fit: BoxFit.cover,
                                            onError: (_, __) {},
                                          )
                                        : null,
                                  ),
                                  child: series.cover.isEmpty
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
                                        series.name ?? "",
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
                                        '${series.episodeRunTime} | Movie | 2h 44m 31s',
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
                      }, childCount: seriesCtrl.series.length),
                    ),

                    // Loading Indicator for Pagination
                    if (seriesCtrl.isMoreLoading.value)
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
