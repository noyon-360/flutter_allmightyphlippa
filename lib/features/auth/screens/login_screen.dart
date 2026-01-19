import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/common/widgets/app_scaffold.dart';
import 'package:flutter_almightyflippa/core/common/widgets/button_widgets.dart';
import 'package:flutter_almightyflippa/core/constants/assest_const.dart'
    hide Icons;
import 'package:flutter_almightyflippa/features/auth/controller/auth_controller.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

// Assuming these exist based on context
import '../../../core/common/widgets/app_logo.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/input_decoration_extensions.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.put(AuthController());

    return AppScaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600, minWidth: 300),
                child: Form(
                  key: authCtrl.loginCtrl.loginFormKey,
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Gap(h: 60),
                        Center(
                          child: AppLogo(
                            height: 134,
                            width: 134,
                            borderRadius: 22.69,
                            images: AssetsConstants.images.logo,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Gap.h40,
                        Text(
                          "Login To Your Account",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primaryWhite,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        Gap.h12,

                        Obx(
                          () =>
                              authCtrl
                                  .loginCtrl
                                  .loginErrorMessage
                                  .value
                                  .isNotEmpty
                              ? Center(
                                  child: Text(
                                    authCtrl.loginCtrl.loginErrorMessage.value,
                                    style: TextStyle(color: AppColors.red),
                                  ),
                                )
                              : SizedBox.shrink(),
                        ),

                        Gap.h12,

                        TextFormField(
                          controller: authCtrl.loginCtrl.emailController,
                          focusNode: authCtrl.loginCtrl.emailFocus,
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
                          ).requestFocus(authCtrl.loginCtrl.passwordFocus),
                          autofillHints: const [AutofillHints.email],
                        ),
                        Gap.h16,

                        Obx(
                          () => TextFormField(
                            controller: authCtrl.loginCtrl.passwordController,
                            focusNode: authCtrl.loginCtrl.passwordFocus,
                            obscureText:
                                authCtrl.loginCtrl.obscurePassword.value,
                            textInputAction: TextInputAction.done,
                            style: TextStyle(color: AppColors.primaryWhite),
                            decoration: context.primaryInputDecoration.copyWith(
                              hintText: "Enter your Password",
                              suffixIcon: IconButton(
                                icon: Icon(
                                  authCtrl.loginCtrl.obscurePassword.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.primaryGray,
                                ),
                                onPressed: () =>
                                    authCtrl.loginCtrl.toggleObscurePassword(),
                              ),
                            ),
                            // validator: Validators.password,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Password is required";
                              }
                              return null;
                            },
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => authCtrl.loginCtrl.login(),
                          ),
                        ),

                        // Forget Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: Text("Forget Password"),
                            ),
                          ],
                        ),

                        PrimaryButton(
                          text: "Login",
                          onApiPressed: () => authCtrl.loginCtrl.login(),
                        ),

                        Gap.h24,

                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don’t have an account? ",
                                style: TextStyle(color: AppColors.primaryGray),
                              ),
                              GestureDetector(
                                onTap: () => Get.to(() => const SignupScreen()),
                                child: Text(
                                  'Sign Up',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
