import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/services/premium_service.dart';
import '../../epg/controllers/epg_controller.dart';
import '../../epg/models/epg_program_model.dart';
import '../../genre/controllers/genre_controller.dart';
import '../../genre/screens/category_selection_screen.dart';
import '../../playlist/models/server_request_model.dart';
import '../../search/controllers/search_controller.dart';
import '../../search/screens/search_screen.dart';
import '../../video/screens/live_video_play_screen.dart';
import '../controllers/live_tv_controller.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  final liveTvCtrl = Get.find<LiveTvController>();

  final searchController = SearchingController();
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

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
      liveTvCtrl.getLiveTvList(isLoadMore: true);
    }
  }

  void _showAllCategories(BuildContext context, GenreController genreCtrl) {
    Get.to(
      () => CategorySelectionScreen(
        title: 'Live TV Categories',
        genreTag: 'channels',
        selectedCategoryId: liveTvCtrl.selectedCategoryId,
        onCategorySelected: (categoryId) {
          liveTvCtrl.getLiveTvList(categoryId: categoryId);
        },
      ),
    );
  }

  void _showEpgSheet(BuildContext context, int streamId, String channelName) {
    final epgCtrl = EpgController.to;
    epgCtrl.fetchEpg(streamId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.containerBgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.tv, color: AppColors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        channelName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      'Upcoming Programs',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white12),
              Expanded(
                child: Obx(() {
                  if (epgCtrl.isLoadingEpg.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.red),
                    );
                  }
                  if (epgCtrl.programs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No EPG data available for this channel.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: epgCtrl.programs.length,
                    separatorBuilder: (_, i) =>
                        const Divider(color: Colors.white12, height: 1),
                    itemBuilder: (_, index) {
                      final program = epgCtrl.programs[index];
                      return _EpgProgramTile(
                        program: program,
                        channelId: streamId.toString(),
                        channelName: channelName,
                        epgCtrl: epgCtrl,
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        final screenWidth = MediaQuery.of(context).size.width;
        int crossAxisCount = 2;
        if (screenWidth >= 900) {
          crossAxisCount = 4;
        } else if (screenWidth >= 600) {
          crossAxisCount = 3;
        }

        return Column(
          children: [
            // Search Bar
            /// [Todo: Implement search bar later]
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onTap: () =>
                    Get.to(() => SearchScreen(type: ServerType.channels)),
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Search Channel',
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

            // Categories Header
            GetBuilder<GenreController>(
              init: GenreController(),
              tag: 'channels',
              builder: (genreCtrl) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primaryWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Gap(h: 10),
                      if (genreCtrl.genres.length > 8)
                        GestureDetector(
                          onTap: () => _showAllCategories(context, genreCtrl),
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
                );
              },
            ),

            // Categories
            Container(
              height: 35,
              margin: const EdgeInsets.only(bottom: 16),
              child: GetBuilder<GenreController>(
                init: GenreController(),
                tag: 'channels',
                builder: (genreCtrl) {
                  return Obx(
                    () => ListView.builder(
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
                              liveTvCtrl.selectedCategoryId.value == categoryId;

                          return GestureDetector(
                            onTap: () {
                              liveTvCtrl.getLiveTvList(categoryId: categoryId);
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
                                      : AppColors.primaryWhite.withOpacity(0.1),
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
                  );
                },
              ),
            ),
            // Results Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: GetBuilder<GenreController>(
                tag: 'channels',
                builder: (genreCtrl) {
                  return Obx(() {
                    String title = 'All Channels';
                    if (liveTvCtrl.selectedCategoryId.value.isNotEmpty) {
                      final genre = genreCtrl.genres.firstWhereOrNull(
                        (g) =>
                            g.categoryId == liveTvCtrl.selectedCategoryId.value,
                      );
                      title = genre?.categoryName ?? 'Channels';
                    }

                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primaryWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
            Expanded(
              child: liveTvCtrl.isLoading.value
                  ? _buildShimmerGrid(crossAxisCount)
                  : RefreshIndicator.adaptive(
                onRefresh: () async {
                  await liveTvCtrl.getLiveTvList();
                },
                color: AppColors.red,
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount:
                      liveTvCtrl.liveTvList.length +
                      (liveTvCtrl.isMoreLoading.value ? crossAxisCount : 0),
                  itemBuilder: (context, index) {
                    if (index >= liveTvCtrl.liveTvList.length) {
                      return _buildSingleShimmerItem();
                    }

                    final channel = liveTvCtrl.liveTvList[index];
                    return TvFocusWrapper(
                      onTap: () {
                        // Live video play screen
                        Get.to(
                          () => LiveVideoPlayScreen(
                            streamId: channel.streamId,
                            channelName: channel.name,
                          ),
                        );
                      },
                      borderRadius: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.containerBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryWhite.withOpacity(0.05),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Background/Icon
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: channel.streamIcon.isNotEmpty
                                    ? Image.network(
                                        channel.streamIcon,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.tv,
                                                color: AppColors.iconColor,
                                                size: 40,
                                              );
                                            },
                                      )
                                    : const Icon(
                                        Icons.tv,
                                        color: AppColors.iconColor,
                                        size: 40,
                                      ),
                              ),
                            ),

                            // Bottom Overlay for Name
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  channel.name,
                                  style: const TextStyle(
                                    color: AppColors.primaryWhite,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            // EPG bell — premium only
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Obx(() {
                                if (!PremiumService.to.isPremium.value) {
                                  return const SizedBox.shrink();
                                }
                                return GestureDetector(
                                  onTap: () => _showEpgSheet(
                                    context,
                                    channel.streamId,
                                    channel.name,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.55,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.notifications_none,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
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
  }

  Widget _buildShimmerGrid(int crossAxisCount) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: crossAxisCount * 4,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) => _buildSingleShimmerItem(),
    );
  }

  Widget _buildSingleShimmerItem() {
    return Shimmer.fromColors(
      baseColor: AppColors.containerBgColor,
      highlightColor: AppColors.primaryWhite.withValues(alpha: 0.1),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.containerBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _EpgProgramTile extends StatelessWidget {
  final EpgProgramModel program;
  final String channelId;
  final String channelName;
  final EpgController epgCtrl;

  const _EpgProgramTile({
    required this.program,
    required this.channelId,
    required this.channelName,
    required this.epgCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(program.startTime);
    final isNow =
        program.isNowPlaying ||
        (program.startTime.isBefore(DateTime.now()) &&
            program.endTime.isAfter(DateTime.now()));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              timeStr,
              style: TextStyle(
                color: isNow ? AppColors.red : Colors.white54,
                fontSize: 12,
                fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isNow)
            Container(
              width: 3,
              height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.title,
                  style: TextStyle(
                    color: isNow ? Colors.white : Colors.white70,
                    fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isNow)
                  const Text(
                    'Now Playing',
                    style: TextStyle(color: AppColors.red, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (program.isFuture)
            Obx(() {
              final hasReminder = epgCtrl.hasReminder(program, channelId);
              return GestureDetector(
                onTap: hasReminder
                    ? null
                    : () => epgCtrl.setReminder(
                        channelId: channelId,
                        channelName: channelName,
                        program: program,
                      ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    hasReminder
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    color: hasReminder ? AppColors.red : Colors.white38,
                    size: 20,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
