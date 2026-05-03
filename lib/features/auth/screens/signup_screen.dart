import 'package:flutter/material.dart';
import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '/core/common/widgets/app_logo.dart';
import '/core/common/widgets/button_widgets.dart';
import '/core/constants/assest_const.dart' hide Icons;
import '/features/auth/controller/register_controller.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '/core/constants/app_colors.dart';
import '/core/common/widgets/app_scaffold.dart';
import '/core/extensions/input_decoration_extensions.dart';
import 'package:flutter/gestures.dart';
import '../../app/screens/privacy_policy_screen.dart';
import '../../app/screens/terms_condition_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final registerCtrl = Get.put(RegisterController());

    return AppScaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),

              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 600,
                  minWidth: 300,
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Form(
                  key: registerCtrl.registerFormKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: AppLogo(
                          height: 120,
                          width: 120,
                          borderRadius: 20,
                          images: AssetsConstants.images.logo,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Create Your Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.primaryWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Obx(
                        () =>
                            registerCtrl.registerErrorMessage.value.isNotEmpty
                            ? Center(
                                child: Text(
                                  registerCtrl.registerErrorMessage.value,
                                  style: TextStyle(color: AppColors.red),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 12),

                      // Name field
                      TextFormField(
                        autofocus: true,
                        controller: registerCtrl.nameController,
                        focusNode: registerCtrl.nameFocus,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryWhite,
                        ),
                        decoration: context.primaryInputDecoration.copyWith(
                          hintText: "Name",
                        ),
                        validator: Validators.name,
                        onFieldSubmitted: (_) => FocusScope.of(
                          context,
                        ).requestFocus(registerCtrl.emailFocus),
                      ),
                      Gap.h16,

                      // Email field
                      TextFormField(
                        controller: registerCtrl.emailController,
                        focusNode: registerCtrl.emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryWhite,
                        ),
                        decoration: context.primaryInputDecoration.copyWith(
                          hintText: "Email",
                        ),
                        validator: Validators.email,
                        onFieldSubmitted: (_) => FocusScope.of(
                          context,
                        ).requestFocus(registerCtrl.passwordFocus),
                        autofillHints: const [AutofillHints.email],
                      ),
                      Gap.h16,

                      // Password field
                      Obx(
                        () => TextFormField(
                          controller: registerCtrl.passwordController,
                          focusNode: registerCtrl.passwordFocus,
                          obscureText: registerCtrl.obscurePassword.value,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: AppColors.primaryWhite),
                          decoration: context.primaryInputDecoration.copyWith(
                            hintText: "Password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                registerCtrl.obscurePassword.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.primaryGray,
                              ),
                              onPressed: () =>
                                  registerCtrl.toggleObscurePassword(),
                            ),
                          ),
                          validator: Validators.password,
                          onFieldSubmitted: (_) => FocusScope.of(
                            context,
                          ).requestFocus(registerCtrl.confirmPasswordFocus),
                        ),
                      ),
                      Gap.h16,

                      // Confirm Password field
                      Obx(
                        () => TextFormField(
                          controller: registerCtrl.confirmPasswordController,
                          focusNode: registerCtrl.confirmPasswordFocus,
                          obscureText:
                              registerCtrl.obscureConfirmPassword.value,
                          textInputAction: TextInputAction.done,
                          style: TextStyle(color: AppColors.primaryWhite),
                          decoration: context.primaryInputDecoration.copyWith(
                            hintText: "Confirm Password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                registerCtrl.obscureConfirmPassword.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.primaryGray,
                              ),
                              onPressed: () =>
                                  registerCtrl.toggleObscureConfirmPassword(),
                            ),
                          ),
                          validator: (value) => Validators.confirmPassword(
                            registerCtrl.passwordController.text,
                            value,
                          ),
                          onFieldSubmitted: (_) => registerCtrl.register(),
                        ),
                      ),
                      Gap.h16,

                      // Terms and Conditions
                      TvFocusWrapper(
                        onTap: () => registerCtrl.toggleAgreeToTerms(),
                        child: Obx(
                          () => CheckboxListTile(
                            value: registerCtrl.agreeToTerms.value,
                            onChanged: (value) =>
                                registerCtrl.toggleAgreeToTerms(),
                            title: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: "I agree to "),
                                  TextSpan(
                                    text: "Terms & Conditions",
                                    style: const TextStyle(
                                      color: AppColors.primaryWhite,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Get.to(
                                          () => const TermsConditionScreen(),
                                        );
                                      },
                                  ),
                                  const TextSpan(text: " and "),
                                  TextSpan(
                                    text: "Privacy Policy",
                                    style: const TextStyle(
                                      color: AppColors.primaryWhite,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Get.to(
                                          () => const PrivacyPolicyScreen(),
                                        );
                                      },
                                  ),
                                ],
                              ),
                              style: const TextStyle(
                                color: AppColors.primaryWhite,
                                fontSize: 14,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.red,
                            checkColor: AppColors.primaryBlack,
                          ),
                        ),
                      ),
                      Gap.h16,

                      // Sign Up button
                      PrimaryButton(
                        text: "Sign up",
                        onApiPressed: () => registerCtrl.register(),
                        focusNode: registerCtrl.signUpButtonFocus,
                      ),
                      Gap.h24,

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(color: AppColors.primaryGray),
                          ),
                          TvFocusWrapper(
                            onTap: () => Get.back(),
                            child: Text(
                              'Sign in',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
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
