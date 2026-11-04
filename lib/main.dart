import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_almightyflippa/core/common/widgets/tv_layout.dart';
import 'package:flutter_almightyflippa/core/common/widgets/tv_shortcuts.dart';
import 'package:flutter_almightyflippa/core/config/app_theme.dart';
import 'package:flutter_almightyflippa/core/services/theme_service.dart';
import 'package:flutter_almightyflippa/core/utils/tv_device.dart';
import 'package:flutter_almightyflippa/features/app/screens/app_decision_screen.dart';
import 'package:get/get.dart';
import 'core/init/app_initializer.dart';
import 'features/notifications/services/notification_inbox_service.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background messages are delivered silently by FCM on Android.
  // No local notification is shown here because the system tray handles it.
  await NotificationInboxService.savePending(message);
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
    // Service setup is wrapped in a try/catch in AppInitializer, so don't
    // assume it registered.
    final themeMode = Get.isRegistered<ThemeService>()
        ? ThemeService.to.themeMode.value
        : ThemeService.defaultMode;

    return GetMaterialApp(
      title: 'LABBY TV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (context, child) {
        // Screens without an AppBar still need status bar icons that
        // contrast with the active theme. Player screens set their own.
        Widget app = AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.overlayStyle(Theme.of(context).brightness),
          child: child!,
        );
        if (TvDevice.isTv) app = TvShortcuts(child: TvLayout(child: app));
        return app;
      },

      home: const AppDecisionScreen(),
    );
  }
}
