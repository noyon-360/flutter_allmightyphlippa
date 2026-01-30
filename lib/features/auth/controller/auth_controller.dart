import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../models/change_password_request_model.dart';
import '../repo/auth_repo.dart';

class AuthController extends GetxController {
  final _authRepo = Get.find<AuthRepo>();

  // TextControllers
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // FocusNodes
  final oldPasswordFocus = FocusNode();
  final newPasswordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();

  // Form Key
  final changePasswordFormKey = GlobalKey<FormState>();

  // States
  final RxString errorMessage = "".obs;
  final RxBool obscureOldPassword = true.obs;
  final RxBool obscureNewPassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;
  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    oldPasswordFocus.dispose();
    newPasswordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.onClose();
  }

  void toggleObscureOldPassword() => obscureOldPassword.toggle();
  void toggleObscureNewPassword() => obscureNewPassword.toggle();
  void toggleObscureConfirmPassword() => obscureConfirmPassword.toggle();

  void _clearFields() {
    oldPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
  }

  Future<void> changePassword() async {
    if (changePasswordFormKey.currentState?.validate() ?? false) {
      errorMessage.value = "";
      isLoading.value = true;

      final request = ChangePasswordRequestModel(
        oldPassword: oldPasswordController.text,
        newPassword: newPasswordController.text,
      );

      final result = await _authRepo.changePassword(request);

      isLoading.value = false;

      result.fold(
        (failure) {
          errorMessage.value = failure.message;
        },
        (success) {
          Get.back();
          Get.snackbar(
            "Success",
            "Password changed successfully",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.primaryBlack.withAlpha(
              (0.2 * 255).toInt(),
            ),
            colorText: AppColors.primaryWhite,
          );
          _clearFields();
        },
      );
    }
  }

  Future<void> deleteAccount() async {
    isLoading.value = true;

    final result = await _authRepo.deleteAccount();

    isLoading.value = false;

    result.fold(
      (failure) {
        errorMessage.value = failure.message;
      },
      (success) {
        Get.back();
        _clearFields();
      },
    );
  }
}
