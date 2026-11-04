import 'package:flutter/material.dart';
import 'package:flutx_core/core/debug_print.dart';
import 'package:get/get.dart';

import '../constants/key_constants.dart';
import 'hive_storage_service.dart';

/// Holds the user's Dark / Light / System choice and persists it in Hive.
/// Kept in Hive (not secure storage) so it survives logout like other device
/// preferences, and is read synchronously before the first frame.
class ThemeService extends GetxService {
  static ThemeService get to => Get.find();

  /// Existing users have only ever seen the dark theme, so that stays the
  /// default until they pick something else.
  static const ThemeMode defaultMode = ThemeMode.dark;

  final Rx<ThemeMode> themeMode = defaultMode.obs;

  @override
  void onInit() {
    super.onInit();
    themeMode.value = _load();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode.value == mode) return;
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    try {
      await HiveStorageService().put(KeyConstants.themeMode, encode(mode));
    } catch (e) {
      DPrint.error('ThemeService: could not save theme mode: $e');
    }
  }

  ThemeMode _load() {
    if (!HiveStorageService.isInitialized) return defaultMode;
    try {
      return decode(
        HiveStorageService().get<String?>(KeyConstants.themeMode),
      );
    } catch (e) {
      DPrint.error('ThemeService: could not read theme mode: $e');
      return defaultMode;
    }
  }

  static String encode(ThemeMode mode) => mode.name;

  static ThemeMode decode(String? value) => ThemeMode.values.firstWhere(
    (m) => m.name == value,
    orElse: () => defaultMode,
  );

  static String label(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System default',
    ThemeMode.dark => 'Dark',
    ThemeMode.light => 'Light',
  };
}
