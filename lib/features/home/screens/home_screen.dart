import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // final homeCtrl = Get.put(HomeController());

  @override
  void initState() {
    super.initState();
    // homeCtrl.getMovies();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Home'));
  }
}
