import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/epg_timeline_controller.dart';
import '../models/epg_program_model.dart';
import '../services/epg_timeline_cache.dart';
import 'epg_program_info_sheet.dart';

const double _kRowHeight = 64;
const double _kMinBlockWidth = 36;

/// One channel's row in the EPG timeline grid: a fixed logo/name column plus
/// a horizontal strip of program blocks for [day], positioned along the
/// timeline shared with every other row and the ruler via
/// [EpgTimelineController.timelineScrollController].
///
/// Fetching happens in [initState]/[didUpdateWidget], so it only fires for
/// rows a `ListView.builder` actually builds (visible channels) and only
/// re-fires when [day] changes — never for a whole category up front.
class EpgTimelineChannelRow extends StatefulWidget {
  final int streamId;
  final String channelName;
  final String channelLogo;
  final DateTime day;

  /// Called when the logo column or the current-program block is tapped.
  /// Left to the caller (rather than navigating internally) because
  /// switching to another channel from inside a screen of the same widget
  /// type needs `Get.off(..., preventDuplicates: false)` — GetX derives an
  /// unnamed route's name from its widget type, so `Get.to` would silently
  /// no-op when this row already sits inside a `LiveVideoPlayScreen`.
  final ValueChanged<int> onOpenChannel;

  const EpgTimelineChannelRow({
    super.key,
    required this.streamId,
    required this.channelName,
    required this.channelLogo,
    required this.day,
    required this.onOpenChannel,
  });

  @override
  State<EpgTimelineChannelRow> createState() => _EpgTimelineChannelRowState();
}

class _EpgTimelineChannelRowState extends State<EpgTimelineChannelRow> {
  @override
  void initState() {
    super.initState();
    Get.find<EpgTimelineCache>().ensureLoaded(widget.streamId, widget.day);
  }

  @override
  void didUpdateWidget(covariant EpgTimelineChannelRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day != widget.day) {
      Get.find<EpgTimelineCache>().ensureLoaded(widget.streamId, widget.day);
    }
  }

  void _openChannel() {
    widget.onOpenChannel(widget.streamId);
  }

  void _showProgramInfo(EpgProgramModel program, bool isFuture) {
    showEpgProgramInfoSheet(
      context,
      program: program,
      streamId: widget.streamId,
      channelName: widget.channelName,
      isFuture: isFuture,
    );
  }

  @override
  Widget build(BuildContext context) {
    final timelineCtrl = Get.find<EpgTimelineController>();
    final cache = Get.find<EpgTimelineCache>();
    final dayStart = widget.day;
    final dayEnd = dayStart.add(const Duration(days: 1));

    return SizedBox(
      height: _kRowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 96,
            child: TvFocusWrapper(
              onTap: _openChannel,
              borderRadius: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.containerBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: widget.channelLogo.isNotEmpty
                          ? Image.network(
                              widget.channelLogo,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.tv,
                                color: AppColors.iconColor,
                              ),
                            )
                          : const Icon(Icons.tv, color: AppColors.iconColor),
                    ),
                    Text(
                      widget.channelName,
                      style: const TextStyle(
                        color: AppColors.primaryWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() {
              final isLoaded = cache.isLoaded(widget.streamId, widget.day);
              final programs = cache.peek(widget.streamId, widget.day);

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: timelineCtrl.timelineScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  width: EpgTimelineController.dayWidth,
                  height: _kRowHeight,
                  child: !isLoaded
                      ? _RowShimmer()
                      : programs.isEmpty
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Text(
                              'No program info',
                              style: TextStyle(
                                color: AppColors.primaryGray,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                      : Stack(
                          children: [
                          ...programs.map((program) {
                            final clampedStart = program.startTime.isBefore(
                              dayStart,
                            )
                                ? dayStart
                                : program.startTime;
                            final clampedEnd = program.endTime.isAfter(dayEnd)
                                ? dayEnd
                                : program.endTime;

                            final left = timelineCtrl.offsetForTime(
                              dayStart,
                              clampedStart,
                            );
                            final width = (timelineCtrl.offsetForTime(
                                      dayStart,
                                      clampedEnd,
                                    ) -
                                    left)
                                .clamp(_kMinBlockWidth, EpgTimelineController.dayWidth);

                            final now = DateTime.now();
                            final isCurrent =
                                program.startTime.isBefore(now) &&
                                program.endTime.isAfter(now);
                            final isPast =
                                !isCurrent && program.endTime.isBefore(now);
                            final isFuture = !isCurrent && !isPast;

                            return Positioned(
                              left: left,
                              width: width,
                              top: 0,
                              bottom: 0,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: TvFocusWrapper(
                                  onTap: isCurrent
                                      ? _openChannel
                                      : () =>
                                            _showProgramInfo(program, isFuture),
                                  borderRadius: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? AppColors.red.withOpacity(0.85)
                                          : AppColors.containerBgColor,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isCurrent
                                            ? AppColors.red
                                            : AppColors.primaryWhite
                                                  .withOpacity(0.08),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                                ? AppColors.primaryWhite
                                                      .withOpacity(0.85)
                                                : AppColors.primaryGray,
                                            fontSize: 9,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                            if (timelineCtrl.isToday)
                              Positioned(
                                left: timelineCtrl.offsetForTime(
                                  dayStart,
                                  DateTime.now(),
                                ),
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 2,
                                  color: AppColors.red,
                                ),
                              ),
                          ],
                        ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RowShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.containerBgColor,
      highlightColor: AppColors.primaryWhite.withOpacity(0.08),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 220,
          height: _kRowHeight - 16,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.containerBgColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}
