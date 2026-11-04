import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';

import '../constants/app_colors.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

extension InputDecorationExtensions on BuildContext {
  InputDecoration get primaryInputDecoration => InputDecoration(
    filled: true,
    suffixIconColor: palette.textPrimary,
    contentPadding: AppSizes.paddingMd.all,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.paddingSm.size),
      borderSide: BorderSide(color: palette.textSecondary),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.paddingSm.size),
      borderSide: BorderSide(color: palette.textSecondary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.paddingSm.size),
      borderSide: BorderSide(color: AppColors.red, width: 2.0),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.paddingSm.size),
      borderSide: BorderSide(color: AppColors.red, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.paddingSm.size),
      borderSide: BorderSide(color: AppColors.red, width: 1.5),
    ),
    hintStyle: TextStyle(
      color: palette.hint,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    labelStyle: TextStyle(
      color: palette.hint,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    errorStyle: TextStyle(
      color: AppColors.red,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
  );
}
