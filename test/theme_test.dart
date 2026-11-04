import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';
import 'package:flutter_almightyflippa/core/config/app_theme.dart';
import 'package:flutter_almightyflippa/core/constants/app_colors.dart';
import 'package:flutter_almightyflippa/core/services/theme_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeService encode/decode', () {
    test('round-trips every mode', () {
      for (final mode in ThemeMode.values) {
        expect(ThemeService.decode(ThemeService.encode(mode)), mode);
      }
    });

    test('nothing stored keeps existing users on dark', () {
      expect(ThemeService.decode(null), ThemeMode.dark);
    });

    test('unknown stored value falls back to dark', () {
      expect(ThemeService.decode('sepia'), ThemeMode.dark);
      expect(ThemeService.decode(''), ThemeMode.dark);
    });

    test('labels', () {
      expect(ThemeService.label(ThemeMode.dark), 'Dark');
      expect(ThemeService.label(ThemeMode.light), 'Light');
      expect(ThemeService.label(ThemeMode.system), 'System default');
    });
  });

  group('AppPalette', () {
    test('dark palette matches the original dark colours', () {
      // The dark theme must look exactly as it did before light was added.
      const p = AppPalette.dark;
      expect(p.background, AppColors.primaryBlack);
      expect(p.surface, AppColors.containerBgColor);
      expect(p.surfaceHigh, AppColors.iconBgColor);
      expect(p.textPrimary, AppColors.primaryWhite);
      expect(p.textSecondary, AppColors.primaryGray);
      expect(p.hint, AppColors.hintText);
    });

    test('light palette has dark text on a light background', () {
      const p = AppPalette.light;
      expect(p.background.computeLuminance(), greaterThan(0.8));
      expect(p.textPrimary.computeLuminance(), lessThan(0.05));
      expect(p.textSecondary.computeLuminance(), lessThan(0.3));
    });

    test('lerp hits both ends and tolerates null', () {
      const a = AppPalette.dark;
      const b = AppPalette.light;
      expect(a.lerp(b, 0).background, a.background);
      expect(a.lerp(b, 1).background, b.background);
      expect(a.lerp(b, 1).textPrimary, b.textPrimary);
      expect(identical(a.lerp(null, 0.5), a), isTrue);
    });

    test('copyWith replaces only the given colour', () {
      final p = AppPalette.dark.copyWith(surface: const Color(0xFF123456));
      expect(p.surface, const Color(0xFF123456));
      expect(p.background, AppPalette.dark.background);
      expect(p.textPrimary, AppPalette.dark.textPrimary);
    });
  });

  group('AppTheme', () {
    test('each theme carries its palette and brightness', () {
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.dark.extension<AppPalette>(), AppPalette.dark);
      expect(AppTheme.light.extension<AppPalette>(), AppPalette.light);
      expect(AppTheme.light.scaffoldBackgroundColor, AppPalette.light.background);
    });

    testWidgets('context.palette follows the active theme mode', (
      tester,
    ) async {
      Future<AppPalette> paletteFor(ThemeMode mode) async {
        late AppPalette seen;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            home: Builder(
              builder: (context) {
                seen = context.palette;
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        return seen;
      }

      expect(await paletteFor(ThemeMode.dark), AppPalette.dark);
      expect(await paletteFor(ThemeMode.light), AppPalette.light);
    });

    testWidgets('a forced dark Theme (players) wins over a light app', (
      tester,
    ) async {
      late AppPalette seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          themeMode: ThemeMode.light,
          home: Theme(
            data: AppTheme.dark,
            child: Builder(
              builder: (context) {
                seen = context.palette;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(seen, AppPalette.dark);
    });

    testWidgets('palette falls back to dark outside the app theme', (
      tester,
    ) async {
      late AppPalette seen;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              seen = context.palette;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, AppPalette.dark);
    });
  });
}
