import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '/core/common/widgets/app_scaffold.dart';
import '/core/common/widgets/button_widgets.dart';
import '/core/constants/app_colors.dart';
import '/core/extensions/input_decoration_extensions.dart';
import '/features/auth/controller/forgot_password_controller.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

/// Step 1 of forgot password: enter the account email to receive an OTP.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  /// Prefilled from the login screen's email field, if any.
  final String? initialEmail;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ForgotPasswordController());
    if (ctrl.emailController.text.isEmpty &&
        (initialEmail?.isNotEmpty ?? false)) {
      ctrl.emailController.text = initialEmail!;
    }

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, color: context.palette.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: ctrl.emailFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Gap.h24,
                  Text(
                    "Forgot Password",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.palette.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Gap.h12,
                  Text(
                    "Enter your account email and we'll send you a verification code.",
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
                  TextFormField(
                    autofocus: true,
                    controller: ctrl.emailController,
                    focusNode: ctrl.emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(
                      fontSize: 16,
                      color: context.palette.textPrimary,
                    ),
                    decoration: context.primaryInputDecoration.copyWith(
                      hintText: "Email",
                    ),
                    validator: Validators.email,
                    onFieldSubmitted: (_) => ctrl.sendOtp(),
                    autofillHints: const [AutofillHints.email],
                  ),
                  Gap.h24,
                  PrimaryButton(
                    text: "Send Code",
                    onApiPressed: () => ctrl.sendOtp(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
