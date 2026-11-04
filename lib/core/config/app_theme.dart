import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import 'app_palette.dart';

class AppTheme {
  static final ThemeData dark = _build(AppPalette.dark, Brightness.dark);
  static final ThemeData light = _build(AppPalette.light, Brightness.light);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark
        ? ColorScheme.dark(primary: p.textPrimary)
        : ColorScheme.light(primary: p.textPrimary);
    final focus = _focusStyle(p);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      colorScheme: base.copyWith(
        surface: p.background,
        onSurface: p.textPrimary,
        onPrimary: p.background,
        error: AppColors.red,
      ),
      extensions: [p],
      textTheme: _textTheme(p.textPrimary),
      iconTheme: IconThemeData(color: p.textPrimary),
      dividerColor: p.surface,
      appBarTheme: AppBarThemeData(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: p.textPrimary,
        ),
        centerTitle: false,
        // Status bar icons must contrast with the app bar, not the OS mode.
        systemOverlayStyle: overlayStyle(brightness),
      ),
      dialogTheme: DialogThemeData(backgroundColor: p.surface),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: p.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surface,
        contentTextStyle: TextStyle(color: p.textPrimary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.red,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.textPrimary,
        selectionHandleColor: AppColors.red,
      ),

      // Focus highlights only appear after remote/keyboard input (never on
      // touch), so these only matter on Android TV — where the Material
      // defaults are too faint to see from the sofa.
      focusColor: p.focusHighlight,
      iconButtonTheme: IconButtonThemeData(style: focus),
      textButtonTheme: TextButtonThemeData(style: focus),
      elevatedButtonTheme: ElevatedButtonThemeData(style: focus),
      outlinedButtonTheme: OutlinedButtonThemeData(style: focus),
    );
  }

  static SystemUiOverlayStyle overlayStyle(Brightness themeBrightness) =>
      themeBrightness == Brightness.dark
      ? SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        )
      : SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        );

  /// Only the focused overlay is set; every other state resolves to null and
  /// falls back to each button's default. An IconButton given its own
  /// `color:` builds a style that outranks the theme, so pass this as its
  /// `style:` (e.g. a PopupMenuButton's) to keep the highlight visible.
  static ButtonStyle focusStyleOf(BuildContext context) =>
      _focusStyle(context.palette);

  static ButtonStyle _focusStyle(AppPalette p) => ButtonStyle(
    overlayColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.focused) ? p.focusHighlight : null,
    ),
  );

  static TextTheme _textTheme(Color color) {
    TextStyle s(FontWeight w, [double? size]) => TextStyle(
      fontFamily: 'Manrope',
      fontWeight: w,
      fontSize: size,
      color: color,
    );
    return TextTheme(
      displayLarge: s(FontWeight.w700),
      displayMedium: s(FontWeight.w700),
      displaySmall: s(FontWeight.w600),
      headlineLarge: s(FontWeight.w700, 32),
      headlineMedium: s(FontWeight.w600, 28),
      headlineSmall: s(FontWeight.w600, 24),
      titleLarge: s(FontWeight.w600, 22),
      titleMedium: s(FontWeight.w500, 18),
      titleSmall: s(FontWeight.w500, 16),
      bodyLarge: s(FontWeight.w400, 16),
      bodyMedium: s(FontWeight.w400, 14),
      bodySmall: s(FontWeight.w400, 12),
      labelLarge: s(FontWeight.w500, 14),
      labelMedium: s(FontWeight.w500, 12),
      labelSmall: s(FontWeight.w500, 11),
    ).apply(bodyColor: color, displayColor: color);
  }
}
