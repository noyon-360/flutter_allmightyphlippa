import 'package:flutter/material.dart';
import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/utils/tv_device.dart';
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
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

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
                          color: context.palette.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Obx(
                        () => registerCtrl.registerErrorMessage.value.isNotEmpty
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
                          color: context.palette.textPrimary,
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
                          color: context.palette.textPrimary,
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
                          style: TextStyle(color: context.palette.textPrimary),
                          decoration: context.primaryInputDecoration.copyWith(
                            hintText: "Password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                registerCtrl.obscurePassword.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: context.palette.textSecondary,
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
                          style: TextStyle(color: context.palette.textPrimary),
                          decoration: context.primaryInputDecoration.copyWith(
                            hintText: "Confirm Password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                registerCtrl.obscureConfirmPassword.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: context.palette.textSecondary,
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
                                  _link(
                                    context,
                                    "Terms & Conditions",
                                    () => Get.to(
                                      () => const TermsConditionScreen(),
                                    ),
                                  ),
                                  const TextSpan(text: " and "),
                                  _link(
                                    context,
                                    "Privacy Policy",
                                    () => Get.to(
                                      () => const PrivacyPolicyScreen(),
                                    ),
                                  ),
                                ],
                              ),
                              style: TextStyle(
                                color: context.palette.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.red,
                            checkColor: context.palette.background,
                          ),
                        ),
                      ),
                      if (TvDevice.isTv) _tvLinks(context),
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
                            style: TextStyle(
                              color: context.palette.textSecondary,
                            ),
                          ),
                          TvFocusWrapper(
                            onTap: () => Get.back(),
                            child: Text(
                              'Sign in',
                              style: TextStyle(
                                color: context.palette.textPrimary,
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

  TextStyle _linkStyle(BuildContext context) => TextStyle(
    color: context.palette.textPrimary,
    fontWeight: FontWeight.bold,
    decoration: TextDecoration.underline,
  );

  /// An underlined link inside the "I agree to ..." sentence: tappable on
  /// phones. A remote can't reach a link inside text, so on TV it's plain
  /// text here and [_tvLinks] adds focusable buttons below instead.
  InlineSpan _link(BuildContext context, String text, VoidCallback onTap) {
    return TextSpan(
      text: text,
      style: _linkStyle(context),
      recognizer: TvDevice.isTv
          ? null
          : (TapGestureRecognizer()..onTap = onTap),
    );
  }

  /// TV only: the Terms / Privacy links as buttons the remote can reach.
  Widget _tvLinks(BuildContext context) {
    Widget button(String text, VoidCallback onTap) => TvFocusWrapper(
      onTap: onTap,
      borderRadius: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(text, style: _linkStyle(context)),
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        button(
          "Terms & Conditions",
          () => Get.to(() => const TermsConditionScreen()),
        ),
        const SizedBox(width: 24),
        button(
          "Privacy Policy",
          () => Get.to(() => const PrivacyPolicyScreen()),
        ),
      ],
    );
  }
}
