import 'package:flutter_almightyflippa/features/auth/repo/auth_repo_impl.dart';
import 'package:flutter_almightyflippa/features/profile/repo/profile_repo.dart';
import 'package:flutter_almightyflippa/features/profile/repo/profile_repo_impl.dart';
import 'package:get/get.dart';

import '../../features/auth/repo/auth_repo.dart';
import '../utils/getx_helper.dart';

Future<void> setupRepository() async {
  Get.getOrPutLazy<AuthRepo>(
    () => AuthRepoImpl(apiClient: Get.find()),
    fenix: true,
  );

  Get.getOrPutLazy<ProfileRepo>(
    () => ProfileRepoImpl(apiClient: Get.find()),
    fenix: true,
  );
}
