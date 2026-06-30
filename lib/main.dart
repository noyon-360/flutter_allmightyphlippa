import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/config/app_theme.dart';
import 'package:flutter_almightyflippa/features/app/screens/app_decision_screen.dart';
import 'package:get/get.dart';
import 'core/init/app_initializer.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background messages are delivered silently by FCM on Android.
  // No local notification is shown here because the system tray handles it.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
