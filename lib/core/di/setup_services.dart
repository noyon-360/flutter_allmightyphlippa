import 'package:get/get.dart';
import '../../core/services/watch_history_service.dart';
import '../../core/services/cast_service.dart';

// import '../network/services/auth_check_service.dart';

Future<void> setupServices() async {
  //Get.getOrPutLazy(() => AuthenticateCheckService(Get.find(), Get.find()));
  Get.put(WatchHistoryService());
  // Chromecast service (lives for the whole app lifetime).
  Get.put(CastService(), permanent: true);
}
