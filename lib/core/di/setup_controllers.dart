import 'package:flutter_almightyflippa/core/utils/getx_helper.dart';
import 'package:flutter_almightyflippa/features/movie/controllers/movie_controller.dart';
import 'package:flutter_almightyflippa/features/profile/controller/profile_controller.dart';
import 'package:flutter_almightyflippa/features/series/controllers/series_controller.dart';
import 'package:flutter_almightyflippa/features/subscription/controllers/subscription_controller.dart';
import 'package:get/get.dart';

import '../../features/search/controllers/search_controller.dart'
    as search_ctrl;

import '../../features/tv/controllers/live_tv_controller.dart';

Future<void> setupControllers() async {
  Get.getOrPutLazy(() => ProfileController(), fenix: true);
  Get.getOrPutLazy(() => MovieController(), fenix: true);
  Get.getOrPutLazy(() => SeriesController(), fenix: true);
  Get.getOrPutLazy(() => LiveTvController(), fenix: true);
  Get.getOrPutLazy(() => search_ctrl.SearchingController(), fenix: true);
  Get.getOrPutLazy(() => SubscriptionController(), fenix: true);
  Get.getOrPutLazy(() => search_ctrl.SearchingController(), fenix: true);
}
