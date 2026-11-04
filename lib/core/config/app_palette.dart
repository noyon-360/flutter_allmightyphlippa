import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';

/// Colours that change between the dark and light theme. Read them with
/// `context.palette` so a widget rebuilds when the theme changes.
///
/// Brand colours (`AppColors.red`, `AppColors.successGreen`) and colours drawn
/// over video or poster art (white text, black scrims) are the same in both
/// themes, so they stay as constants in [AppColors].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.textPrimary,
    required this.textSecondary,
    required this.hint,
    required this.focusHighlight,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  /// Scaffold / page background.
  final Color background;

  /// Cards, tiles, dialogs, sheets and input fills on top of [background].
  final Color surface;

  /// One step above [surface]: icon chips, selected chips, track backgrounds.
  final Color surfaceHigh;

  /// Main text and icons on [background] or [surface].
  final Color textPrimary;

  /// Secondary text, captions, chevrons, borders.
  final Color textSecondary;

  /// Placeholder text in inputs.
  final Color hint;

  /// TV focus overlay on buttons; must stand out against [background].
  final Color focusHighlight;

  final Color shimmerBase;
  final Color shimmerHighlight;

  /// For code with no BuildContext (controllers showing snackbars). Reads
  /// the navigator's context, which sits under the app theme.
  static AppPalette get current => Get.context?.palette ?? dark;

  static const dark = AppPalette(
    background: AppColors.primaryBlack,
    surface: AppColors.containerBgColor,
    surfaceHigh: AppColors.iconBgColor,
    textPrimary: AppColors.primaryWhite,
    textSecondary: AppColors.primaryGray,
    hint: AppColors.hintText,
    focusHighlight: Color(0x52FFFFFF), // white, 32%
    shimmerBase: Color(0xFF383838),
    shimmerHighlight: Color(0xFF484848),
  );

  // Mirrors the dark theme's layering: the page is the plainest layer and
  // surfaces sit one shade off it, so cards still read as cards.
  static const light = AppPalette(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF1F1F3),
    surfaceHigh: Color(0xFFDCDCE0),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF5F5F66),
    hint: Color(0xFF8A8A90),
    focusHighlight: Color(0x2E000000), // black, 18%
    shimmerBase: Color(0xFFE4E4E8),
    shimmerHighlight: Color(0xFFF2F2F5),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? textPrimary,
    Color? textSecondary,
    Color? hint,
    Color? focusHighlight,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      hint: hint ?? this.hint,
      focusHighlight: focusHighlight ?? this.focusHighlight,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      hint: Color.lerp(hint, other.hint, t)!,
      focusHighlight: Color.lerp(focusHighlight, other.focusHighlight, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// Falls back to dark so a widget built outside the app theme (tests,
  /// overlays with their own Theme) still gets the colours it always had.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}

extension AppThemeBrightness on BuildContext {
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
}
