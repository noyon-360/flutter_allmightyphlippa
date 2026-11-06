import 'package:get/get.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/parental_lock_service.dart';
import '../../core/services/watch_history_service.dart';
import '../../core/services/cast_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/revenuecat_service.dart';
import '../../core/services/premium_service.dart';
import '../../features/downloads/services/download_service.dart';
import '../../features/epg/services/live_tv_now_playing_cache.dart';
import '../../features/epg/services/epg_timeline_cache.dart';
import '../../features/notifications/services/notification_inbox_service.dart';

Future<void> setupServices() async {
  Get.put(ThemeService(), permanent: true);
  await Get.putAsync<ParentalLockService>(
    () => ParentalLockService().init(),
    permanent: true,
  );
  Get.put(WatchHistoryService());
  Get.put(CastService(), permanent: true);
  Get.put(RevenueCatService(), permanent: true);
  Get.put(PremiumService(), permanent: true);
  // NotificationService records into the inbox as soon as it starts.
  await Get.putAsync<NotificationInboxService>(
    () => NotificationInboxService().init(),
    permanent: true,
  );
  Get.put(NotificationService(), permanent: true);
  Get.put(LiveTvNowPlayingCache(), permanent: true);
  Get.put(EpgTimelineCache(), permanent: true);
  await Get.putAsync<DownloadService>(() => DownloadService().init(), permanent: true);
}
