import 'package:get/get.dart';

import '../api/api_client.dart';
import '../services/auth_storage_service.dart';

Future<void> setupCore() async {
  Get.lazyPut(() => ApiClient(), fenix: true);
  Get.lazyPut(() => AuthStorageService(), fenix: true);
}
