import 'package:get/get.dart';
import '../../core/services/watch_history_service.dart';
import '../../core/services/cast_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/revenuecat_service.dart';
import '../../core/services/premium_service.dart';
import '../../features/downloads/services/download_service.dart';

Future<void> setupServices() async {
  Get.put(WatchHistoryService());
  Get.put(CastService(), permanent: true);
  Get.put(RevenueCatService(), permanent: true);
  Get.put(PremiumService(), permanent: true);
  Get.put(NotificationService(), permanent: true);
  await Get.putAsync<DownloadService>(() => DownloadService().init(), permanent: true);
}
