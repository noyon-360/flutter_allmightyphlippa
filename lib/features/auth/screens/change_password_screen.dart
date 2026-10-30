import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';
import '../../../core/common/widgets/app_scaffold.dart';
import '../../../core/common/widgets/button_widgets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/input_decoration_extensions.dart';
import '../controller/auth_controller.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.put(AuthController());

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, color: AppColors.primaryWhite),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Change Password",
          style: TextStyle(color: AppColors.primaryWhite),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: authCtrl.changePasswordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Obx(
                        () => authCtrl.errorMessage.value.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Center(
                                  child: Text(
                                    authCtrl.errorMessage.value,
                                    style: TextStyle(color: AppColors.red),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Old Password
                      Obx(
                        () => TextFormField(
                          controller: authCtrl.oldPasswordController,
                          focusNode: authCtrl.oldPasswordFocus,
                          obscureText: authCtrl.obscureOldPassword.value,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: AppColors.primaryWhite),
                          decoration: context.primaryInputDecoration.copyWith(
                            hintText: "Old Password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                authCtrl.obscureOldPassword.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.primaryGray,
                              ),
                              onPressed: authCtrl.toggleObscureOldPassword,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Old password is required";
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => FocusScope.of(
                            context,
                          ).requestFocus(authCtrl.newPasswordFocus),
                        ),
                      ),
                      const Gap(h: 16),

                      // New Password
                      Obx(
                        () => TextFormField(
                          controller: authCtrl.newPasswordController,
                          focusNode: authCtrl.newPasswordFocus,
                          obscureText: authCtrl.obscureNewPassword.value,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: AppColors.primaryWhite),
                          decoration: context.primaryInputDecoration.copyWith(
                            hintText: "New Password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                authCtrl.obscureNewPassword.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.primaryGray,
                              ),
                              onPressed: authCtrl.toggleObscureNewPassword,
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
                          ).requestFocus(authCtrl.confirmPasswordFocus),
                        ),
                      ),
                      const Gap(h: 16),

                      // Confirm Password
                      Obx(
                        () => TextFormField(
                          controller: authCtrl.confirmPasswordController,
                          focusNode: authCtrl.confirmPasswordFocus,
                          obscureText: authCtrl.obscureConfirmPassword.value,
                          textInputAction: TextInputAction.done,
                          style: TextStyle(color: AppColors.primaryWhite),
                          decoration: context.primaryInputDecoration.copyWith(
                            hintText: "Confirm New Password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                authCtrl.obscureConfirmPassword.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.primaryGray,
                              ),
                              onPressed: authCtrl.toggleObscureConfirmPassword,
                            ),
                          ),
                          validator: (value) {
                            if (value != authCtrl.newPasswordController.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => authCtrl.changePassword(),
                        ),
                      ),
                      const Gap(h: 40),

                      PrimaryButton(
                        text: "Change Password",
                        onApiPressed: () => authCtrl.changePassword(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
