import 'package:get/get.dart';
import '../../core/services/watch_history_service.dart';
import '../../core/services/cast_service.dart';
import '../../core/services/revenuecat_service.dart';

Future<void> setupServices() async {
  Get.put(WatchHistoryService());
  Get.put(CastService(), permanent: true);
  Get.put(RevenueCatService(), permanent: true);
}
