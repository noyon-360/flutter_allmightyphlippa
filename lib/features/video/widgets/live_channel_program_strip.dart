import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../epg/models/epg_program_model.dart';
import '../../epg/services/epg_timeline_cache.dart';
import '../../epg/widgets/epg_program_info_sheet.dart';

const double _kChipWidth = 112;
const int _kContextCount = 10; // programs shown before/after the current one

/// Horizontal strip of the current channel's surrounding 10 previous + 10
/// next programs, sourced from [EpgTimelineCache] (the same cache the EPG
/// grid uses, so revisiting a channel/day already fetched is free).
///
/// Lives *below* the video player, not overlaid on top of it — on a short
/// 16:9 video area this row is tall enough that overlaying it fought the
/// play/pause button for the same screen space, so it's a plain, always-
/// visible section instead of part of [LiveVideoControls]'s auto-hiding
/// overlay chrome.
class LiveChannelProgramStrip extends StatefulWidget {
  final int streamId;
  final String channelName;

  const LiveChannelProgramStrip({
    super.key,
    required this.streamId,
    required this.channelName,
  });

  @override
  State<LiveChannelProgramStrip> createState() =>
      _LiveChannelProgramStripState();
}

class _LiveChannelProgramStripState extends State<LiveChannelProgramStrip> {
  bool _didAutoScroll = false;
  Timer? _tickTimer;
  final ScrollController _stripController = ScrollController();

  @override
  void initState() {
    super.initState();
    Get.find<EpgTimelineCache>().ensureLoadedAround(
      widget.streamId,
      DateTime.now(),
    );
    // The current-program highlight advances with the wall clock even when
    // nothing else triggers a rebuild — repaint periodically so it doesn't
    // go stale during a long-idle view.
    _tickTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant LiveChannelProgramStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamId != widget.streamId) {
      _didAutoScroll = false;
      Get.find<EpgTimelineCache>().ensureLoadedAround(
        widget.streamId,
        DateTime.now(),
      );
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _stripController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cache = Get.find<EpgTimelineCache>();
      final now = DateTime.now();
      final loaded = cache.isLoadedAround(widget.streamId, now);
      final programs = cache.peekAround(widget.streamId, now);

      final currentIndex = programs.indexWhere(
        (p) => p.startTime.isBefore(now) && p.endTime.isAfter(now),
      );

      return Container(
        height: 58,
        color: AppColors.containerBgColor,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: !loaded
            ? const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: AppColors.red,
                    strokeWidth: 2,
                  ),
                ),
              )
            : programs.isEmpty
            ? const SizedBox.shrink()
            : _buildStrip(programs, currentIndex, now),
      );
    });
  }

  Widget _buildStrip(
    List<EpgProgramModel> programs,
    int currentIndex,
    DateTime now,
  ) {
    final start = currentIndex >= 0
        ? (currentIndex - _kContextCount).clamp(0, programs.length)
        : 0;
    final end = currentIndex >= 0
        ? (currentIndex + _kContextCount + 1).clamp(0, programs.length)
        : programs.length;
    final visible = programs.sublist(start, end);
    final visibleCurrentIndex = currentIndex >= 0 ? currentIndex - start : -1;

    if (!_didAutoScroll && visibleCurrentIndex >= 0) {
      _didAutoScroll = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_stripController.hasClients) return;
        final offset =
            (visibleCurrentIndex * (_kChipWidth + 6)) -
            (_stripController.position.viewportDimension / 2) +
            (_kChipWidth / 2);
        _stripController.jumpTo(
          offset.clamp(0.0, _stripController.position.maxScrollExtent),
        );
      });
    }

    return ListView.separated(
      controller: _stripController,
      scrollDirection: Axis.horizontal,
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (context, index) {
        final program = visible[index];
        final isCurrent = index == visibleCurrentIndex;
        final isPast = !isCurrent && program.endTime.isBefore(now);
        final isFuture = !isCurrent && !isPast;

        return GestureDetector(
          onTap: () {
            showEpgProgramInfoSheet(
              context,
              program: program,
              streamId: widget.streamId,
              channelName: widget.channelName,
              isFuture: isFuture,
            );
          },
          child: Container(
            width: _kChipWidth,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.red : AppColors.primaryBlack,
              borderRadius: BorderRadius.circular(6),
              border: isCurrent
                  ? null
                  : Border.all(color: AppColors.primaryWhite.withValues(alpha: 0.08)),
            ),
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.title,
                  style: TextStyle(
                    color: isPast
                        ? AppColors.primaryGray
                        : AppColors.primaryWhite,
                    fontSize: 11,
                    fontWeight: isCurrent
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  program.timeRange,
                  style: TextStyle(
                    color: isCurrent
                        ? AppColors.primaryWhite.withValues(alpha: 0.85)
                        : AppColors.primaryGray,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
