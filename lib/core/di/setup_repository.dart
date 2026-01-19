import 'package:flutter_almightyflippa/core/utils/getx_helper.dart';
import 'package:flutter_almightyflippa/features/auth/repo/auth_repo_impl.dart';
import 'package:get/get.dart';

import '../../features/auth/repo/auth_repo.dart';

Future<void> setupRepository() async {
  Get.getOrPutLazy<AuthRepo>(
    () => AuthRepoImpl(apiClient: Get.find()),
    fenix: true,
  );
}
