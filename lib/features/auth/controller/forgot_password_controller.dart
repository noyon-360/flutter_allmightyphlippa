import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '/features/auth/controller/login_controller.dart';
import '/features/auth/repo/auth_repo.dart';
import '/features/auth/screens/reset_password_screen.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

/// Drives the two-step forgot-password flow:
/// 1. [ForgotPasswordScreen] — email → `POST /auth/forget` (OTP is emailed)
/// 2. [ResetPasswordScreen] — OTP + new password → `POST /auth/reset-password`
class ForgotPasswordController extends GetxController {
  final AuthRepo _authRepo = Get.find<AuthRepo>();

  // Step 1
  final emailController = TextEditingController();
  final emailFocus = FocusNode();
  final emailFormKey = GlobalKey<FormState>();

  // Step 2
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final otpFocus = FocusNode();
  final passwordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();
  final resetFormKey = GlobalKey<FormState>();

  final RxString errorMessage = "".obs;
  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;
  final RxBool isResending = false.obs;

  /// Email the OTP was sent to; fixed once step 1 succeeds.
  String _email = "";
  String get email => _email;

  @override
  void onClose() {
    emailController.dispose();
    emailFocus.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    otpFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.onClose();
  }

  void toggleObscurePassword() =>
      obscurePassword.value = !obscurePassword.value;

  void toggleObscureConfirmPassword() =>
      obscureConfirmPassword.value = !obscureConfirmPassword.value;

  /// Step 1: request the OTP, then move to the reset screen.
  Future<void> sendOtp() async {
    if (!(emailFormKey.currentState?.validate() ?? false)) return;
    errorMessage.value = "";

    final email = emailController.text.trim();
    final result = await _authRepo.forgetPassword(email);

    result.fold(
      (fail) {
        errorMessage.value = fail.message;
        DPrint.log("Forget password fail : ${fail.message}");
      },
      (success) {
        _email = email;
        otpController.clear();
        passwordController.clear();
        confirmPasswordController.clear();
        _showSnack("Code sent", "Check $email for your verification code");
        Get.to(() => const ResetPasswordScreen());
      },
    );
  }

  /// Re-send the OTP from the reset screen.
  Future<void> resendOtp() async {
    if (isResending.value || _email.isEmpty) return;
    isResending.value = true;
    errorMessage.value = "";

    final result = await _authRepo.forgetPassword(_email);
    isResending.value = false;

    result.fold(
      (fail) => errorMessage.value = fail.message,
      (success) => _showSnack("Code sent", "A new code was sent to $_email"),
    );
  }

  /// Step 2: reset the password, then return to the login screen.
  Future<void> resetPassword() async {
    if (!(resetFormKey.currentState?.validate() ?? false)) return;
    errorMessage.value = "";

    final result = await _authRepo.resetPassword(
      email: _email,
      otp: otpController.text.trim(),
      password: passwordController.text,
    );

    result.fold(
      (fail) {
        errorMessage.value = fail.message;
        DPrint.log("Reset password fail : ${fail.message}");
      },
      (success) {
        // Prefill the login form so the user can sign in straight away.
        if (Get.isRegistered<LoginController>()) {
          final login = Get.find<LoginController>();
          login.emailController.text = _email;
          login.passwordController.clear();
          login.loginErrorMessage.value = "";
        }
        // Pop the reset screen and the email screen, back to login. Close
        // any snackbar first: while one is showing, Get.back() only closes
        // the snackbar instead of popping a screen.
        Get.closeAllSnackbars();
        Get.back();
        Get.back();
        _showSnack("Success", "Password reset. Please log in.");
      },
    );
  }

  void _showSnack(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppPalette.current.background.withAlpha((0.2 * 255).toInt()),
      colorText: AppPalette.current.textPrimary,
    );
  }
}
