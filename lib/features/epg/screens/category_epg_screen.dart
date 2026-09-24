import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../tv/controllers/live_tv_controller.dart';
import '../../tv/models/live_tv_reponse_model.dart';
import '../../video/screens/live_video_play_screen.dart';
import '../controllers/epg_timeline_controller.dart';
import '../services/epg_timeline_cache.dart';
import '../services/live_tv_now_playing_cache.dart';
import '../widgets/epg_timeline_channel_row.dart';
import '../widgets/epg_timeline_day_nav.dart';
import '../widgets/epg_timeline_ruler.dart';

/// Full TV guide for the Live TV category currently selected on the Live TV
/// tab — Premium only (the tab only offers it to Premium users).
///
/// Every channel of the category is a row on one shared time axis: what's
/// airing now, what's next, and (via the day navigation) earlier and later
/// days. It reuses the channels already loaded by [LiveTvController] — same
/// list, same pagination — and the timeline widgets the live player's guide
/// uses, so the two look and behave alike. Each row loads its own programs
/// only as it scrolls into view ([EpgTimelineCache]), which keeps a large
/// category from firing hundreds of guide requests up front.
class CategoryEpgScreen extends StatefulWidget {
  /// Name of the category being shown ("All Channels" when none is selected).
  final String title;

  const CategoryEpgScreen({super.key, required this.title});

  @override
  State<CategoryEpgScreen> createState() => _CategoryEpgScreenState();
}

class _CategoryEpgScreenState extends State<CategoryEpgScreen> {
  final LiveTvController _liveTvCtrl = Get.find<LiveTvController>();
  final EpgTimelineController _timelineCtrl = Get.find<EpgTimelineController>();
  final ScrollController _listController = ScrollController();

  /// Bumped by [_refresh]; part of every row's key, so rows are rebuilt from
  /// scratch (which is what makes them fetch their programs again).
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _listController.addListener(_onScroll);
    // Always open on today, at the current time.
    _timelineCtrl.goToToday();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_listController.position.pixels >=
        _listController.position.maxScrollExtent - 200) {
      _liveTvCtrl.getLiveTvList(isLoadMore: true);
    }
  }

  void _openChannel(LiveTvModel channel) {
    Get.to(
      () => LiveVideoPlayScreen(
        streamId: channel.streamId,
        channelName: channel.name,
        channelLogo: channel.streamIcon,
      ),
      // Unnamed route: GetX names it after the widget type, so with the
      // default preventDuplicates a channel opened while another live player
      // is already in the stack would be silently ignored.
      preventDuplicates: false,
    );
  }

  /// Forget every cached program and reload what's on screen.
  void _refresh() {
    Get.find<EpgTimelineCache>().clear();
    Get.find<LiveTvNowPlayingCache>().clear();
    _timelineCtrl.goToToday();
    setState(() => _generation++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        titleSpacing: 0,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh guide',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final channels = _liveTvCtrl.liveTvList;

          if (channels.isEmpty) {
            return Center(
              child: _liveTvCtrl.isLoading.value
                  ? const CircularProgressIndicator(color: AppColors.red)
                  : const Text(
                      'No channels in this category.',
                      style: TextStyle(color: Colors.white54),
                    ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: EpgTimelineDayNav(timelineCtrl: _timelineCtrl),
              ),
              EpgTimelineRuler(timelineCtrl: _timelineCtrl),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: Obx(() {
                  final day = _timelineCtrl.selectedDate.value;
                  final loadingMore = _liveTvCtrl.isMoreLoading.value;
                  return ListView.separated(
                    controller: _listController,
                    padding: const EdgeInsets.all(12),
                    itemCount: channels.length + (loadingMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index >= channels.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.red,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        );
                      }

                      final channel = channels[index];
                      return EpgTimelineChannelRow(
                        key: ValueKey('${channel.streamId}-$_generation'),
                        streamId: channel.streamId,
                        channelName: channel.name,
                        channelLogo: channel.streamIcon,
                        day: day,
                        onOpenChannel: (_) => _openChannel(channel),
                      );
                    },
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }
}
