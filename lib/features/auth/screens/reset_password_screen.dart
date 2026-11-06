import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '/core/common/widgets/app_scaffold.dart';
import '/core/common/widgets/button_widgets.dart';
import '/core/common/widgets/tv_focus_wrapper.dart';
import '/core/constants/app_colors.dart';
import '/core/extensions/input_decoration_extensions.dart';
import '/features/auth/controller/forgot_password_controller.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

/// Step 2 of forgot password: enter the emailed OTP and a new password.
/// Pushed by [ForgotPasswordController.sendOtp], which owns the controller.
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  static const int _otpLength = 6;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ForgotPasswordController>();

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.adaptive.arrow_back,
            color: context.palette.textPrimary,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: ctrl.resetFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Gap.h24,
                  Text(
                    "Reset Password",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.palette.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Gap.h12,
                  Text(
                    "Enter the code sent to ${ctrl.email} and choose a new password.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.palette.textSecondary),
                  ),
                  Gap.h24,
                  Obx(
                    () => ctrl.errorMessage.value.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              ctrl.errorMessage.value,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.red),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Verification code
                  TextFormField(
                    autofocus: true,
                    controller: ctrl.otpController,
                    focusNode: ctrl.otpFocus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(_otpLength),
                    ],
                    style: TextStyle(
                      fontSize: 16,
                      color: context.palette.textPrimary,
                      letterSpacing: 4,
                    ),
                    decoration: context.primaryInputDecoration.copyWith(
                      hintText: "Verification code",
                    ),
                    validator: (value) {
                      if ((value?.trim().length ?? 0) != _otpLength) {
                        return "Enter the $_otpLength-digit code";
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(ctrl.passwordFocus),
                    autofillHints: const [AutofillHints.oneTimeCode],
                  ),
                  Gap.h16,

                  // New password
                  Obx(
                    () => TextFormField(
                      controller: ctrl.passwordController,
                      focusNode: ctrl.passwordFocus,
                      obscureText: ctrl.obscurePassword.value,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(color: context.palette.textPrimary),
                      decoration: context.primaryInputDecoration.copyWith(
                        hintText: "New Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            ctrl.obscurePassword.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: context.palette.textSecondary,
                          ),
                          onPressed: ctrl.toggleObscurePassword,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "New password is required";
                        }
                        if (value.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => FocusScope.of(
                        context,
                      ).requestFocus(ctrl.confirmPasswordFocus),
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                  ),
                  Gap.h16,

                  // Confirm password
                  Obx(
                    () => TextFormField(
                      controller: ctrl.confirmPasswordController,
                      focusNode: ctrl.confirmPasswordFocus,
                      obscureText: ctrl.obscureConfirmPassword.value,
                      textInputAction: TextInputAction.done,
                      style: TextStyle(color: context.palette.textPrimary),
                      decoration: context.primaryInputDecoration.copyWith(
                        hintText: "Confirm New Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            ctrl.obscureConfirmPassword.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: context.palette.textSecondary,
                          ),
                          onPressed: ctrl.toggleObscureConfirmPassword,
                        ),
                      ),
                      validator: (value) {
                        if (value != ctrl.passwordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => ctrl.resetPassword(),
                    ),
                  ),
                  Gap.h24,

                  PrimaryButton(
                    text: "Reset Password",
                    onApiPressed: () => ctrl.resetPassword(),
                  ),
                  Gap.h24,

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't get the code? ",
                        style: TextStyle(color: context.palette.textSecondary),
                      ),
                      Obx(
                        () => TvFocusWrapper(
                          onTap: ctrl.isResending.value
                              ? null
                              : () => ctrl.resendOtp(),
                          child: Text(
                            ctrl.isResending.value ? "Sending..." : "Resend",
                            style: TextStyle(
                              color: context.palette.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gap.h24,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
