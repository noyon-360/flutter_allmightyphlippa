import 'package:get/get.dart';

import '../repositories/movie_repo.dart';

class MovieController extends GetxController {
  final _movieRepo = Get.find<MovieRepo>();

  Future<void> getMovies() async {
    await _movieRepo.getMovies();
  }
}
