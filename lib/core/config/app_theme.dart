import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
    scaffoldBackgroundColor: AppColors.primaryBlack,
    // primaryColor: AppColors.primaryWhite,
    colorScheme: ColorScheme.dark(primary: AppColors.primaryWhite),

    textTheme:
        const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            color: AppColors.primaryWhite,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            color: AppColors.primaryWhite,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
            color: AppColors.primaryWhite,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            fontSize: 32,
            color: AppColors.primaryWhite,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
            fontSize: 28,
            color: AppColors.primaryWhite,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: AppColors.primaryWhite,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: AppColors.primaryWhite,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: AppColors.primaryWhite,
          ),
          titleSmall: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: AppColors.primaryWhite,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: AppColors.primaryWhite,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: AppColors.primaryWhite,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: AppColors.primaryWhite,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppColors.primaryWhite,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: AppColors.primaryWhite,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: AppColors.primaryWhite,
          ),
        ).apply(
          bodyColor: AppColors.primaryWhite,
          displayColor: AppColors.primaryWhite,
        ),

    appBarTheme: AppBarThemeData(
      backgroundColor: AppColors.primaryBlack,
      titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
      centerTitle: false,
    ),

    // Focus highlights only appear after remote/keyboard input (never on
    // touch), so these only matter on Android TV — where the Material
    // defaults are too faint to see on this dark theme from the sofa.
    focusColor: _focusHighlight,
    iconButtonTheme: IconButtonThemeData(style: focusStyle),
    textButtonTheme: TextButtonThemeData(style: focusStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(style: focusStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: focusStyle),
  );

  static const Color _focusHighlight = Color(0x52FFFFFF); // white, 32%

  // Only the focused overlay is set; every other state resolves to null and
  // falls back to each button's default. An IconButton given its own
  // `color:` builds a style that outranks the theme, so pass this as its
  // `style:` (e.g. a PopupMenuButton's) to keep the highlight visible.
  static final ButtonStyle focusStyle = ButtonStyle(
    overlayColor: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.focused) ? _focusHighlight : null,
    ),
  );
}
