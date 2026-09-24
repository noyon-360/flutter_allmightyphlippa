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

  /// Where "now" sits within the visible timeline: 25% in from the left edge,
  /// so a little of what just aired stays visible before the current program.
  static const double _nowViewportFraction = 0.25;

  /// Width of everything beside the timeline strip on a channel row (logo
  /// column + gap, 104) plus the list's horizontal padding (24). Only used to
  /// estimate the viewport before any scrollable has laid out.
  static const double _nonTimelineWidth = 128;

  final Rx<DateTime> selectedDate = _todayMidnight().obs;
  late final ScrollController timelineScrollController;

  @override
  void onInit() {
    super.onInit();
    // Every row and the ruler attach their own position to this controller;
    // starting each one at "now" (rather than 12:00 AM) means rows built
    // lazily while scrolling also open on the current time. Not persisting
    // the offset keeps that deterministic across visits.
    timelineScrollController = _NowScrollController();
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => scrollToNow(animate: true),
    );
  }

  /// Scrolls every attached timeline strip (ruler + rows) so the current
  /// time is near the left edge. No-op until something has attached.
  void scrollToNow({bool animate = false}) {
    if (!timelineScrollController.hasClients) return;
    final viewport =
        timelineScrollController.positions.first.viewportDimension;
    final target = _offsetForNow(viewport);
    if (animate) {
      timelineScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      timelineScrollController.jumpTo(target);
    }
  }

  /// Estimated width of the timeline strip before anything has laid out.
  /// Read from the platform dispatcher rather than `Get.width`: this
  /// controller is built at startup, before the app has a `BuildContext`,
  /// and `Get.width` throws a null-check error there.
  static double _estimatedViewport() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return dayWidth;
    final view = views.first;
    return view.physicalSize.width / view.devicePixelRatio - _nonTimelineWidth;
  }

  static double _offsetForNow(double viewport) {
    final now = DateTime.now();
    final minutes = now.difference(_todayMidnight()).inMinutes;
    final maxOffset = (dayWidth - viewport).clamp(0.0, dayWidth);
    return (minutes * pxPerMinute - viewport * _nowViewportFraction)
        .clamp(0.0, maxOffset);
  }

  /// Horizontal pixel offset of [time] within [dayStart]'s timeline.
  double offsetForTime(DateTime dayStart, DateTime time) {
    return time.difference(dayStart).inMinutes * pxPerMinute;
  }
}

/// A [ScrollController] whose initial offset is "now" evaluated each time a
/// scrollable attaches, not once at construction — so a controller created at
/// app launch still opens on the current time hours later.
class _NowScrollController extends ScrollController {
  _NowScrollController() : super(keepScrollOffset: false);

  @override
  double get initialScrollOffset =>
      EpgTimelineController._offsetForNow(
        EpgTimelineController._estimatedViewport(),
      );
}
