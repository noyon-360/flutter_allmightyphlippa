import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/common/widgets/tv_focus_wrapper.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../playlist/models/server_request_model.dart';
import '../../video/screens/video_play_screen.dart';
import '../controllers/history_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final historyCtrl = Get.put(HistoryController());
  final ScrollController _scrollController = ScrollController();

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
      historyCtrl.getHistory(isLoadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryBlack,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (historyCtrl.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.red),
          );
        }

        if (historyCtrl.history.isEmpty) {
          return const Center(
            child: Text(
              'No history found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final grouped = historyCtrl.groupedHistory;
        final keys = grouped.keys.toList();

        return RefreshIndicator.adaptive(
          onRefresh: () async {
            await historyCtrl.getHistory();
          },
          color: AppColors.red,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              for (var key in keys) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = grouped[key]![index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TvFocusWrapper(
                        onTap: () {
                          // Try to parse streamId, default to 0 if fails
                          final streamId = int.tryParse(item.videoId) ?? 0;
                          final type = item.videoType.toLowerCase() == 'series'
                              ? ServerType.series
                              : ServerType.movies;

                          Get.to(
                            () =>
                                VideoPlayScreen(streamId: streamId, type: type),
                          );
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 120,
                                height: 68,
                                color: AppColors.containerBgColor,
                                child: Stack(
                                  children: [
                                    if (item.thumbnail.isNotEmpty)
                                      Positioned.fill(
                                        child: Image.network(
                                          item.thumbnail,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox(),
                                        ),
                                      ),
                                    // Progress Bar
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: LinearProgressIndicator(
                                        value: item.progressPercentage / 100,
                                        backgroundColor: Colors.grey
                                            .withOpacity(0.3),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              AppColors.red,
                                            ),
                                        minHeight: 3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name ?? 'Unknown Title',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _buildSubtitle(item),
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
                  }, childCount: grouped[key]!.length),
                ),
              ],
              if (historyCtrl.isMoreLoading.value)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.red),
                    ),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          ),
        );
      }),
    );
  }

  String _buildSubtitle(dynamic item) {
    // Format: "24 May 2025 | Movie | 2h 44m 31s"
    final date = item.lastWatchedAt != null
        // Manual formatting to match basic requirement or use intl if available
        // simple: day month year
        ? '${item.lastWatchedAt!.day} ${_getMonth(item.lastWatchedAt!.month)} ${item.lastWatchedAt!.year}'
        : '';

    final type = item.videoType.isNotEmpty ? item.videoType : 'Video';
    final duration = _formatDuration(item.duration);

    // Filter out empty parts
    final parts = [date, type, duration].where((p) => p.isNotEmpty).toList();
    return parts.join(' | ');
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  String _formatDuration(double seconds) {
    if (seconds <= 0) return '';
    final duration = Duration(seconds: seconds.toInt());
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);

    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
