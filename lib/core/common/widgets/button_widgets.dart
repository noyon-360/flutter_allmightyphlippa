// import '/core/base/base_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/common/widgets/tv_focus_wrapper.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final Future<void> Function()? onApiPressed; // For API calls (with loading)
  final VoidCallback? onSimplePressed; // For navigation/local actions
  final String? tag;
  final String text;

  final Widget? iconLeft;
  final Widget? iconRight;

  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final FocusNode? focusNode;

  const PrimaryButton({
    super.key,
    this.onApiPressed,
    this.onSimplePressed,
    this.tag,
    required this.text,
    this.iconLeft,
    this.iconRight,
    this.width,
    this.height = 50,
    this.backgroundColor = AppColors.primaryWhite,
    this.textColor = AppColors.primaryBlack,
    this.borderRadius = 25.0,
    this.focusNode,
  });

  String get _uniqueTag => tag ?? text;

  @override
  Widget build(BuildContext context) {
    final isLoading = Get.put(false.obs, tag: _uniqueTag);

    return TvFocusWrapper(
      focusNode: focusNode,
      onTap: onApiPressed != null
          ? () async {
              if (isLoading.value) return;
              isLoading.value = true;

              try {
                await onApiPressed!();
              } catch (e) {
                Get.snackbar(
                  "Error",
                  e.toString(),
                  backgroundColor: Colors.red[600],
                  colorText: Colors.white,
                );
              } finally {
                isLoading.value = false;
                // Optional: auto cleanup after 10 sec
                Future.delayed(const Duration(seconds: 10), () {
                  if (Get.isRegistered<RxBool>(tag: _uniqueTag)) {
                    Get.delete<RxBool>(tag: _uniqueTag);
                  }
                });
              }
            }
          : onSimplePressed,
      child: Obx(() {
        return AbsorbPointer(
          absorbing: isLoading.value,
          child: Opacity(
            opacity: isLoading.value ? 0.6 : 1.0,
            child: Container(
              width: width ?? double.infinity,
              height: height ?? 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: isLoading.value
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (iconLeft != null) ...[
                          iconLeft!,
                          const SizedBox(width: 8),
                        ],
                        Text(
                          text,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        if (iconRight != null) ...[
                          const SizedBox(width: 8),
                          iconRight!,
                        ],
                      ],
                    ),
            ),
          ),
        );
      }),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final Future<void> Function()? onApiPressed; // For API calls (with loading)
  final VoidCallback? onSimplePressed; // For navigation/local actions
  final String? tag;
  final String text;
  final double? width;
  final double? height;
  final Color borderColor;
  final Color textColor;
  final Color? backgroundColor;
  final double borderRadius;
  final FocusNode? focusNode;
  final double borderWidth;
  final Widget? iconLeft;
  final Widget? iconRight;

  const SecondaryButton({
    super.key,
    this.onApiPressed,
    this.onSimplePressed,
    this.tag,
    required this.text,
    this.width,
    this.height = 50,
    this.borderColor = AppColors.primaryWhite,
    this.textColor = AppColors.primaryWhite,
    this.backgroundColor,
    this.borderRadius = 8.0,
    this.borderWidth = 1.0,
    this.iconLeft,
    this.iconRight,
    this.focusNode,
  });

  String get _uniqueTag => tag ?? text;

  @override
  Widget build(BuildContext context) {
    final isLoading = Get.put(false.obs, tag: _uniqueTag);

    return TvFocusWrapper(
      focusNode: focusNode,
      onTap: onApiPressed != null
          ? () async {
              if (isLoading.value) return;
              isLoading.value = true;

              try {
                await onApiPressed!();
              } catch (e) {
                Get.snackbar(
                  "Error",
                  e.toString(),
                  backgroundColor: Colors.red[600],
                  colorText: Colors.white,
                );
              } finally {
                isLoading.value = false;
                // Optional: auto cleanup after 10 sec
                Future.delayed(const Duration(seconds: 10), () {
                  if (Get.isRegistered<RxBool>(tag: _uniqueTag)) {
                    Get.delete<RxBool>(tag: _uniqueTag);
                  }
                });
              }
            }
          : onSimplePressed,
      child: Obx(() {
        return AbsorbPointer(
          absorbing: isLoading.value,
          child: Opacity(
            opacity: isLoading.value ? 0.6 : 1.0,
            child: Container(
              width: width ?? double.infinity,
              height: height ?? 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.transparent,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: isLoading.value
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (iconLeft != null) ...[
                          iconLeft!,
                          const SizedBox(width: 8),
                        ],
                        Text(
                          text,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: AppColors.primaryGray,
                          ),
                        ),
                        if (iconRight != null) ...[
                          const SizedBox(width: 8),
                          iconRight!,
                        ],
                      ],
                    ),
            ),
          ),
        );
      }),
    );
  }
}
