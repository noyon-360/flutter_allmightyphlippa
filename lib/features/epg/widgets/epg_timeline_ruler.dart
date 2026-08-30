import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/epg_timeline_controller.dart';

/// Horizontal time axis shared with every `EpgTimelineChannelRow` via
/// [EpgTimelineController.timelineScrollController] — dragging any row
/// scrolls this in lockstep. Draws a red "now" line when the selected day
/// is today, at the same x-offset the channel rows use for their own
/// current-program highlighting.
class EpgTimelineRuler extends StatelessWidget {
  final EpgTimelineController timelineCtrl;

  /// Width of the leading channel logo/name column in `EpgTimelineChannelRow`
  /// — kept in sync so the ruler's ticks line up with the rows below it.
  final double leadingWidth;

  const EpgTimelineRuler({
    super.key,
    required this.timelineCtrl,
    this.leadingWidth = 104,
  });

  static final _tickFormat = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: leadingWidth),
          Expanded(child: _buildScrollableTicks()),
        ],
      ),
    );
  }

  Widget _buildScrollableTicks() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: timelineCtrl.timelineScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Obx(() {
        final dayStart = timelineCtrl.selectedDate.value;
        final now = DateTime.now();
        final isToday = timelineCtrl.isToday;
        final ticks = List<int>.generate(48, (i) => i * 30);

        return SizedBox(
          width: EpgTimelineController.dayWidth,
          child: Stack(
            children: [
              ...ticks.map((minutes) {
                final tickTime = dayStart.add(Duration(minutes: minutes));
                return Positioned(
                  left: minutes * EpgTimelineController.pxPerMinute,
                  top: 0,
                  bottom: 0,
                  child: Text(
                    _tickFormat.format(tickTime),
                    style: const TextStyle(
                      color: AppColors.primaryGray,
                      fontSize: 10,
                    ),
                  ),
                );
              }),
              if (isToday)
                Positioned(
                  left: timelineCtrl.offsetForTime(dayStart, now),
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: AppColors.red),
                ),
            ],
          ),
        );
      }),
    );
  }
}
