import 'package:flutter_almightyflippa/features/profile/controller/profile_controller.dart';
import 'package:get/get.dart';

import '../utils/getx_helper.dart';

Future<void> setupControllers() async {
  Get.getOrPutLazy<ProfileController>(
    () => ProfileController(Get.find(), Get.find()),
    fenix: true,
  );
}
