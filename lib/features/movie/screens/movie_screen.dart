import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/movie_controller.dart';

class MovieScreen extends StatefulWidget {
  const MovieScreen({super.key});

  @override
  State<MovieScreen> createState() => _MovieScreenState();
}

class _MovieScreenState extends State<MovieScreen> {
  final movieCtrl = Get.put(MovieController());

  @override
  void initState() {
    super.initState();
    movieCtrl.getMovies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Movie')));
  }
}
