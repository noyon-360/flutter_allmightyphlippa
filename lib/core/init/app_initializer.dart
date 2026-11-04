import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutx_core/flutx_core.dart';

import 'package:get/get.dart';
import '../services/hive_storage_service.dart';
import '../utils/tv_device.dart';
import '../di/service_locator.dart';
import '../services/request_queue_service.dart';

class AppInitializer {
  static Future<void> initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();
    MediaKit.ensureInitialized();
    await TvDevice.init();
    if (TvDevice.isTv) {
      // No touchscreen on a TV: always draw focus highlights. Left on
      // automatic, Flutter starts in touch mode and stays there for key
      // events it attributes to a virtual keyboard.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
    }

    // Limit total image cache
    PaintingBinding.instance.imageCache.maximumSize = 100; // 100 images
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MB

    // Allow all orientations at app start
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.landscapeRight,
    // ]);

    await HiveStorageService.init();
    try {
      await setupServiceLocator();
      await Get.find<RequestQueueService>().initialize();
      DPrint.log("Service Locator & Request Queue Setup Completed");
    } catch (err) {
      DPrint.log("Error in Service Locator Setup: $err");
    }

    // SocketClient().connect();
    // Wait for connection
    // SocketClient().onReady;
  }
}
