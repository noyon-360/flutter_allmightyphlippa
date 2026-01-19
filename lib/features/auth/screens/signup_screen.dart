import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/common/widgets/app_logo.dart';
import 'package:flutter_almightyflippa/core/common/widgets/button_widgets.dart';
import 'package:flutter_almightyflippa/core/constants/assest_const.dart'
    hide Icons;
import 'package:flutter_almightyflippa/features/auth/controller/auth_controller.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/common/widgets/app_scaffold.dart';
import '../../../../core/extensions/input_decoration_extensions.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AppScaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 600,
                    minWidth: 300,
                  ),
                  child: Form(
                    key: authCtrl.registerCtrl.registerFormKey,
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 60),
                          Center(
                            child: AppLogo(
                              height: 134,
                              width: 134,
                              borderRadius: 22.69,
                              images: AssetsConstants.images.logo,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // ... rest of the children
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
                                authCtrl
                                    .registerCtrl
                                    .registerErrorMessage
                                    .value
                                    .isNotEmpty
                                ? Center(
                                    child: Text(
                                      authCtrl
                                          .registerCtrl
                                          .registerErrorMessage
                                          .value,
                                      style: TextStyle(color: AppColors.red),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 12),

                          // Name field
                          TextFormField(
                            controller: authCtrl.registerCtrl.nameController,
                            focusNode: authCtrl.registerCtrl.nameFocus,
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
                            ).requestFocus(authCtrl.registerCtrl.emailFocus),
                          ),

                          Gap.h16,

                          // Email field
                          TextFormField(
                            controller: authCtrl.registerCtrl.emailController,
                            focusNode: authCtrl.registerCtrl.emailFocus,
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
                            ).requestFocus(authCtrl.registerCtrl.passwordFocus),
                            autofillHints: const [AutofillHints.email],
                          ),

                          Gap.h16,

                          // Password field
                          Obx(
                            () => TextFormField(
                              controller:
                                  authCtrl.registerCtrl.passwordController,
                              focusNode: authCtrl.registerCtrl.passwordFocus,
                              obscureText:
                                  authCtrl.registerCtrl.obscurePassword.value,
                              textInputAction: TextInputAction.next,
                              style: TextStyle(color: AppColors.primaryWhite),
                              decoration: context.primaryInputDecoration
                                  .copyWith(
                                    hintText: "Password",
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        authCtrl
                                                .registerCtrl
                                                .obscurePassword
                                                .value
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColors.primaryGray,
                                      ),
                                      onPressed: () => authCtrl.registerCtrl
                                          .toggleObscurePassword(),
                                    ),
                                  ),
                              validator: Validators.password,
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).requestFocus(
                                    authCtrl.registerCtrl.confirmPasswordFocus,
                                  ),
                            ),
                          ),

                          Gap.h16,

                          // Confirm Password field
                          Obx(
                            () => TextFormField(
                              controller: authCtrl
                                  .registerCtrl
                                  .confirmPasswordController,
                              focusNode:
                                  authCtrl.registerCtrl.confirmPasswordFocus,
                              obscureText: authCtrl
                                  .registerCtrl
                                  .obscureConfirmPassword
                                  .value,
                              textInputAction: TextInputAction.done,
                              style: TextStyle(color: AppColors.primaryWhite),
                              decoration: context.primaryInputDecoration
                                  .copyWith(
                                    hintText: "Confirm Password",
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        authCtrl
                                                .registerCtrl
                                                .obscureConfirmPassword
                                                .value
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColors.primaryGray,
                                      ),
                                      onPressed: () => authCtrl.registerCtrl
                                          .toggleObscureConfirmPassword(),
                                    ),
                                  ),
                              validator: (value) => Validators.confirmPassword(
                                authCtrl.registerCtrl.passwordController.text,
                                value,
                              ),
                              onFieldSubmitted: (_) =>
                                  authCtrl.registerCtrl.register(),
                            ),
                          ),

                          Gap.h16,

                          // Terms and Conditions
                          Obx(
                            () => CheckboxListTile(
                              value: authCtrl.registerCtrl.agreeToTerms.value,
                              onChanged: (value) =>
                                  authCtrl.registerCtrl.toggleAgreeToTerms(),
                              title: Text(
                                "I agree to Terms & Conditions",
                                style: TextStyle(color: AppColors.primaryWhite),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppColors.primaryWhite,
                              checkColor: AppColors.primaryBlack,
                            ),
                          ),

                          Gap.h16,

                          // Sign Up button
                          PrimaryButton(
                            text: "Sign up",
                            onApiPressed: () =>
                                authCtrl.registerCtrl.register(),
                          ),

                          Gap.h24,

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: TextStyle(color: AppColors.primaryGray),
                              ),
                              GestureDetector(
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

                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
