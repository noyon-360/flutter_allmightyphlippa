import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/epg_timeline_controller.dart';

/// Compact backward/forward day navigation for the EPG timeline —
/// "< Today >", switching to the "EEE, MMM d" formatted date once the
/// selected day is no longer today.
class EpgTimelineDayNav extends StatelessWidget {
  final EpgTimelineController timelineCtrl;

  const EpgTimelineDayNav({super.key, required this.timelineCtrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final day = timelineCtrl.selectedDate.value;
      final isToday = timelineCtrl.isToday;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.chevron_left,
              color: AppColors.primaryWhite,
              size: 20,
            ),
            onPressed: timelineCtrl.goToPreviousDay,
          ),
          Text(
            isToday ? 'Today' : DateFormat('EEE, MMM d').format(day),
            style: const TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.chevron_right,
              color: AppColors.primaryWhite,
              size: 20,
            ),
            onPressed: timelineCtrl.goToNextDay,
          ),
          if (!isToday)
            TextButton(
              onPressed: timelineCtrl.goToToday,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Jump to Today',
                style: TextStyle(color: AppColors.red, fontSize: 12),
              ),
            ),
        ],
      );
    });
  }
}
