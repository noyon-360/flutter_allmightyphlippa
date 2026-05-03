import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/config/app_theme.dart';
import 'package:flutter_almightyflippa/features/app/screens/app_decision_screen.dart';
import 'package:get/get.dart';
import 'core/init/app_initializer.dart';

void main() async {
  await AppInitializer.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'LABBY TV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,

      home: const AppDecisionScreen(),
    );
  }
}
