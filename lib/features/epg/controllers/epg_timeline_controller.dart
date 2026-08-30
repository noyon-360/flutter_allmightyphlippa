import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Drives the EPG timeline screen's date/time-window state and the single
/// [ScrollController] shared by the time ruler and every channel row, so
/// dragging any one of them moves all of them in lockstep. Channel roster,
/// category filtering, and vertical pagination are intentionally *not*
/// owned here — they're reused directly from `LiveTvController`, which the
/// timeline screen is always opened from an already-initialized instance of.
class EpgTimelineController extends GetxController {
  static const double pxPerMinute = 4.0;
  static const int dayWidthMinutes = 24 * 60;
  static double get dayWidth => dayWidthMinutes * pxPerMinute;

  final Rx<DateTime> selectedDate = _todayMidnight().obs;
  late final ScrollController timelineScrollController;

  @override
  void onInit() {
    super.onInit();
    timelineScrollController = ScrollController();
  }

  @override
  void onClose() {
    timelineScrollController.dispose();
    super.onClose();
  }

  static DateTime _todayMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get isToday => selectedDate.value == _todayMidnight();

  void goToPreviousDay() {
    selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));
  }

  void goToNextDay() {
    selectedDate.value = selectedDate.value.add(const Duration(days: 1));
  }

  void goToToday() {
    selectedDate.value = _todayMidnight();
  }

  /// Horizontal pixel offset of [time] within [dayStart]'s timeline.
  double offsetForTime(DateTime dayStart, DateTime time) {
    return time.difference(dayStart).inMinutes * pxPerMinute;
  }
}
