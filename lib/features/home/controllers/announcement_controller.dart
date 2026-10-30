import 'package:get/get.dart';

import '../../../core/services/hive_storage_service.dart';
import '../models/announcement_model.dart';
import '../repositories/announcement_repository.dart';

/// Loads the Home screen's announcements and remembers which the user has
/// closed, so a dismissed one stays gone across launches.
class AnnouncementController extends GetxController {
  static const _dismissedKey = 'dismissed_announcements';
  static const _maxRemembered = 50;

  final AnnouncementRepository _repo = AnnouncementRepository();

  final announcements = <AnnouncementModel>[].obs;
  final _dismissed = <String>{}.obs;

  /// The announcement to show: the first the user hasn't dismissed (the list
  /// is already ordered by priority), or null to show nothing.
  AnnouncementModel? get current =>
      announcements.firstWhereOrNull((a) => !_dismissed.contains(a.dismissKey));

  @override
  void onInit() {
    super.onInit();
    _loadDismissed();
    load();
  }

  void _loadDismissed() {
    if (!HiveStorageService.isInitialized) return;
    final stored = HiveStorageService().get<List?>(
      _dismissedKey,
      defaultValue: const [],
    );
    _dismissed.addAll((stored ?? const []).map((e) => e.toString()));
  }

  Future<void> load() async {
    final result = await _repo.getActive();
    result.fold(
      // Announcements are a nicety: if they can't be fetched, keep whatever
      // is showing (or nothing) rather than surfacing an error on Home.
      (_) {},
      (success) => announcements.assignAll(success.data),
    );
  }

  Future<void> dismiss(AnnouncementModel announcement) async {
    _dismissed.add(announcement.dismissKey);
    if (!HiveStorageService.isInitialized) return;
    // Keep the newest entries only, so the list can't grow forever.
    final all = _dismissed.toList();
    final kept = all.length > _maxRemembered
        ? all.sublist(all.length - _maxRemembered)
        : all;
    await HiveStorageService().put(_dismissedKey, kept);
  }
}
