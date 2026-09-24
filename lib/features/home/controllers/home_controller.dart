import 'package:flutter_almightyflippa/features/movie/controllers/movie_controller.dart';
import 'package:flutter_almightyflippa/features/series/controllers/series_controller.dart';
import 'package:get/get.dart';

import 'announcement_controller.dart';

class HomeController extends GetxController {
  final _movieController = Get.find<MovieController>();
  final _seriesController = Get.find<SeriesController>();

  Future<void> refreshData() async {
    await Future.wait([
      _movieController.getMovies(),
      _seriesController.getSeries(),
      if (Get.isRegistered<AnnouncementController>())
        Get.find<AnnouncementController>().load(),
    ]);
  }
}
