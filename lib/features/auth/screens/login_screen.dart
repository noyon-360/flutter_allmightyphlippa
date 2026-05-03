import 'package:flutter/material.dart';
import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '/core/common/widgets/app_scaffold.dart';
import '/core/common/widgets/button_widgets.dart';
import '/core/constants/assest_const.dart' hide Icons;
import '/features/auth/controller/login_controller.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

// Assuming these exist based on context
import '/core/common/widgets/app_logo.dart';
import '/core/constants/app_colors.dart';
import '/core/extensions/input_decoration_extensions.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginCtrl = Get.put(LoginController());

    return AppScaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600, minWidth: 300),
                child: Form(
                  key: loginCtrl.loginFormKey,
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
                          () => loginCtrl.loginErrorMessage.value.isNotEmpty
                              ? Center(
                                  child: Text(
                                    loginCtrl.loginErrorMessage.value,
                                    style: TextStyle(color: AppColors.red),
                                  ),
                                )
                              : SizedBox.shrink(),
                        ),

                        Gap.h12,

                        TextFormField(
                          autofocus: true,
                          controller: loginCtrl.emailController,
                          focusNode: loginCtrl.emailFocus,
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
                          ).requestFocus(loginCtrl.passwordFocus),
                          autofillHints: const [AutofillHints.email],
                        ),
                        Gap.h16,

                        Obx(
                          () => TextFormField(
                            controller: loginCtrl.passwordController,
                            focusNode: loginCtrl.passwordFocus,
                            obscureText: loginCtrl.obscurePassword.value,
                            textInputAction: TextInputAction.done,
                            style: TextStyle(color: AppColors.primaryWhite),
                            decoration: context.primaryInputDecoration.copyWith(
                              hintText: "Enter your Password",
                              suffixIcon: IconButton(
                                icon: Icon(
                                  loginCtrl.obscurePassword.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.primaryGray,
                                ),
                                onPressed: () =>
                                    loginCtrl.toggleObscurePassword(),
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
                            onFieldSubmitted: (_) => loginCtrl.login(),
                          ),
                        ),

                        // Forget Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TvFocusWrapper(
                              onTap: () {
                                // TODO: Implement forget password
                              },
                              child: Text(
                                "Forget Password",
                                style: TextStyle(color: AppColors.primaryWhite),
                              ),
                            ),
                          ],
                        ),

                        PrimaryButton(
                          text: "Login",
                          onApiPressed: () => loginCtrl.login(),
                          focusNode: loginCtrl.loginButtonFocus,
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
                              TvFocusWrapper(
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
