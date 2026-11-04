import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/config/app_palette.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/theme_service.dart';

/// Dark / Light / System picker. Picking an option applies it and closes
/// the dialog.
Future<void> showThemePickerDialog() {
  return Get.dialog(const _ThemePickerDialog());
}

class _ThemePickerDialog extends StatelessWidget {
  const _ThemePickerDialog();

  static const _options = [
    (ThemeMode.dark, Icons.dark_mode_outlined),
    (ThemeMode.light, Icons.light_mode_outlined),
    (ThemeMode.system, Icons.brightness_auto_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final service = ThemeService.to;
    final p = context.palette;

    return Dialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Appearance',
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Gap.h12,
            Obx(() {
              final current = service.themeMode.value;
              return Column(
                children: [
                  for (final (mode, icon) in _options)
                    TvFocusWrapper(
                      // Remote users land on the current choice.
                      autofocus: mode == current,
                      // Close on pick: on TV there's no tap-outside to
                      // dismiss, so the remote would otherwise be stuck here.
                      onTap: () {
                        service.setThemeMode(mode);
                        Get.back();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: p.textPrimary, size: 22),
                            Gap.w16,
                            Expanded(
                              child: Text(
                                ThemeService.label(mode),
                                style: TextStyle(
                                  color: p.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Icon(
                              mode == current
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: mode == current
                                  ? AppColors.red
                                  : p.textSecondary,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
