import 'package:flutter_almightyflippa/features/movie/controllers/movie_controller.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final _homeRepo = Get.put(MovieController());

  Future<void> getMovies() async {
    await _homeRepo.getMovies();
  }
}