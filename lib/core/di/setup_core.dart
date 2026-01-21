import 'package:flutter_almightyflippa/core/utils/getx_helper.dart';
import 'package:get/get.dart';

import '../api/api_client.dart';
import '../services/auth_storage_service.dart';

Future<void> setupCore() async {
  Get.getOrPut(() => ApiClient());
  Get.getOrPut(() => AuthStorageService());
}
