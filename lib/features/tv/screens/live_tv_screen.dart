import 'package:flutter_almightyflippa/core/services/parental_lock_service.dart';
import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/services/premium_service.dart';
import '../../epg/controllers/epg_controller.dart';
import '../../epg/screens/category_epg_screen.dart';
import '../../epg/models/epg_program_model.dart';
import '../../genre/controllers/genre_controller.dart';
import '../../genre/screens/category_selection_screen.dart';
import '../../playlist/models/server_request_model.dart';
import '../../search/controllers/search_controller.dart';
import '../../search/screens/search_screen.dart';
import '../../video/screens/live_video_play_screen.dart';
import '../controllers/live_tv_controller.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

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
        onCategorySelected: (categoryId) async {
          if (!await ParentalLockService.to.guardCategory(
            ParentalSection.live,
            categoryId,
          )) {
            return;
          }
          liveTvCtrl.getLiveTvList(categoryId: categoryId);
        },
      ),
    );
  }

  void _showEpgSheet(
    BuildContext context,
    int streamId,
    String channelName,
    String channelLogo,
  ) {
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
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.palette.textPrimary.withValues(alpha: 0.24),
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
                        style: TextStyle(
                          color: context.palette.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Upcoming Programs',
                      style: TextStyle(color: context.palette.textPrimary.withValues(alpha: 0.54), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: context.palette.textPrimary.withValues(alpha: 0.12)),
              Expanded(
                child: Obx(() {
                  if (epgCtrl.isLoadingEpg.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.red),
                    );
                  }
                  if (epgCtrl.programs.isEmpty) {
                    return Center(
                      child: Text(
                        'No EPG data available for this channel.',
                        style: TextStyle(color: context.palette.textPrimary.withValues(alpha: 0.54)),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: epgCtrl.programs.length,
                    separatorBuilder: (_, i) =>
                        Divider(color: context.palette.textPrimary.withValues(alpha: 0.12), height: 1),
                    itemBuilder: (_, index) {
                      final program = epgCtrl.programs[index];
                      return _EpgProgramTile(
                        program: program,
                        streamId: streamId,
                        channelId: streamId.toString(),
                        channelName: channelName,
                        channelLogo: channelLogo,
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

        // One scroll view for the whole tab: the search bar, categories and
        // title scroll away with the channels. With only the grid scrolling,
        // a landscape phone had no room left for it (the header filled the
        // short screen) and the channel list couldn't be scrolled at all.
        return RefreshIndicator.adaptive(
          onRefresh: () async {
            await liveTvCtrl.getLiveTvList();
          },
          color: AppColors.red,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search Bar
                    /// [Todo: Implement search bar later]
                    // Looks like a search field but is a button that opens the search
                    // screen: a read-only TextField can't be activated with a TV
                    // remote's OK button (onTap only fires for touch).
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TvFocusWrapper(
                        onTap: () => Get.to(
                          () => SearchScreen(type: ServerType.channels),
                        ),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: context.palette.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 48,
                                child: Icon(
                                  Icons.search,
                                  color: context.palette.textPrimary,
                                ),
                              ),
                              Text(
                                'Search Channel',
                                style: TextStyle(
                                  color: context.palette.hint,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: context.palette.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Gap(h: 10),
                              if (genreCtrl.genres.length > 8)
                                TvFocusWrapper(
                                  onTap: () =>
                                      _showAllCategories(context, genreCtrl),
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
                      // 35 for the chip + the focus ring's 2px on each side.
                      height: 39,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: GetBuilder<GenreController>(
                        init: GenreController(),
                        tag: 'channels',
                        builder: (genreCtrl) {
                          return Obx(
                            () => ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
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
                                final categoryId = isAll
                                    ? ''
                                    : genre!.categoryId;
                                final categoryName = isAll
                                    ? 'All'
                                    : genre!.categoryName;

                                return Obx(() {
                                  final isSelected =
                                      liveTvCtrl.selectedCategoryId.value ==
                                      categoryId;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: TvFocusWrapper(
                                      onTap: () async {
                                        if (!await ParentalLockService.to
                                            .guardCategory(
                                              ParentalSection.live,
                                              categoryId,
                                            )) {
                                          return;
                                        }
                                        liveTvCtrl.getLiveTvList(
                                          categoryId: categoryId,
                                        );
                                      },
                                      borderRadius: 25,
                                      focusColor: context.palette.textPrimary,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.red
                                              : context.palette.surface,
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.red
                                                : context.palette.textPrimary
                                                      .withOpacity(0.1),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          categoryName,
                                          style: TextStyle(
                                            color: isSelected
                                                ? context.palette.textPrimary
                                                : context.palette.textSecondary,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 14,
                                          ),
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
                            if (liveTvCtrl
                                .selectedCategoryId
                                .value
                                .isNotEmpty) {
                              final genre = genreCtrl.genres.firstWhereOrNull(
                                (g) =>
                                    g.categoryId ==
                                    liveTvCtrl.selectedCategoryId.value,
                              );
                              title = genre?.categoryName ?? 'Channels';
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: context.palette.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                // Premium: the whole category as a full TV guide.
                                if (PremiumService.to.isPremium.value)
                                  TextButton.icon(
                                    onPressed: () => Get.to(
                                      () => CategoryEpgScreen(title: title),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.red,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.view_timeline_outlined,
                                    ),
                                    label: const Text(
                                      'Full Guide',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (liveTvCtrl.isLoading.value)
                _buildShimmerGrid(crossAxisCount)
              else if (liveTvCtrl.liveTvList.isEmpty)
                SliverToBoxAdapter(child: _buildLiveTvEmptyOrError())
              else
                SliverPadding(
                  // Bottom: clear of the floating nav bar.
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    MediaQuery.of(context).padding.bottom + 8,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      childCount:
                          liveTvCtrl.liveTvList.length +
                          (liveTvCtrl.isMoreLoading.value ? crossAxisCount : 0),
                      (context, index) {
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
                                channelLogo: channel.streamIcon,
                              ),
                            );
                          },
                          borderRadius: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.palette.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: context.palette.textPrimary.withOpacity(0.05),
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
                                                  return Icon(
                                                    Icons.tv,
                                                    color: context.palette.textPrimary,
                                                    size: 40,
                                                  );
                                                },
                                          )
                                        : Icon(
                                            Icons.tv,
                                            color: context.palette.textPrimary,
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
                                      style: TextStyle(
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
                                        channel.streamIcon,
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
          ),
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

  Widget _buildLiveTvEmptyOrError() {
    final error = liveTvCtrl.errorMessage.value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 60.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            error != null ? Icons.cloud_off : Icons.live_tv_outlined,
            size: 48,
            color: context.palette.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            error != null
                ? "Couldn't load channels.\n$error"
                : 'No channels available',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.textSecondary, fontSize: 14),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => liveTvCtrl.getLiveTvList(),
              icon: const Icon(Icons.refresh, color: AppColors.red),
              label: const Text(
                'Try Again',
                style: TextStyle(color: AppColors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerGrid(int crossAxisCount) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildSingleShimmerItem(),
          childCount: crossAxisCount * 4,
        ),
      ),
    );
  }

  Widget _buildSingleShimmerItem() {
    return Shimmer.fromColors(
      baseColor: context.palette.surface,
      highlightColor: context.palette.textPrimary.withValues(alpha: 0.1),
      child: Container(
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _EpgProgramTile extends StatelessWidget {
  final EpgProgramModel program;
  final int streamId;
  final String channelId;
  final String channelName;
  final String channelLogo;
  final EpgController epgCtrl;

  const _EpgProgramTile({
    required this.program,
    required this.streamId,
    required this.channelId,
    required this.channelName,
    required this.channelLogo,
    required this.epgCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(program.startTime);
    final isNow =
        program.isNowPlaying ||
        (program.startTime.isBefore(DateTime.now()) &&
            program.endTime.isAfter(DateTime.now()));

    return TvFocusWrapper(
      onTap: () {
        Navigator.of(context).pop();
        Get.to(
          () => LiveVideoPlayScreen(
            streamId: streamId,
            channelName: channelName,
            channelLogo: channelLogo,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 68,
              child: Text(
                timeStr,
                style: TextStyle(
                  color: isNow ? AppColors.red : context.palette.textPrimary.withValues(alpha: 0.54),
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
                      color: isNow ? context.palette.textPrimary : context.palette.textPrimary.withValues(alpha: 0.70),
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
                      color: hasReminder ? AppColors.red : context.palette.textPrimary.withValues(alpha: 0.38),
                      size: 20,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
