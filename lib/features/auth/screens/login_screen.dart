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
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import '/core/utils/tv_device.dart';
import '/features/auth/widgets/tv_qr_login_panel.dart';
import '/features/auth/widgets/login_welcome_intro.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginCtrl = Get.put(LoginController());

    final isTv = TvDevice.isTv;

    final form = Align(
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
                      Gap(h: isTv ? 24 : 60),
                      if (!isTv)
                        Center(
                          child: AppLogo(
                            height: 134,
                            width: 134,
                            borderRadius: 22.69,
                            images: AssetsConstants.images.logo,
                            fit: BoxFit.contain,
                          ),
                        ),
                      if (!isTv) Gap.h40,
                      // TV shows the intro once above both columns instead.
                      if (isTv)
                        Text(
                          "Sign in with email",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.palette.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        const LoginWelcomeIntro(),

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
                        autofocus: !isTv,
                        controller: loginCtrl.emailController,
                        focusNode: loginCtrl.emailFocus,
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
                          style: TextStyle(color: context.palette.textPrimary),
                          decoration: context.primaryInputDecoration.copyWith(
                            hintText: "Enter your Password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                loginCtrl.obscurePassword.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: context.palette.textSecondary,
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

                      Gap.h8,

                      // Forget Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TvFocusWrapper(
                            onTap: () => Get.to(
                              () => ForgotPasswordScreen(
                                initialEmail: loginCtrl.emailController.text
                                    .trim(),
                              ),
                            ),
                            // Padding enlarges the tap/focus target.
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 4,
                              ),
                              child: Text(
                                "Forget Password",
                                style: TextStyle(
                                  color: context.palette.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      Gap.h16,

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
                              style: TextStyle(
                                color: context.palette.textSecondary,
                              ),
                            ),
                            TvFocusWrapper(
                              onTap: () => Get.to(() => const SignupScreen()),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: context.palette.textPrimary,
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
    );

    if (!isTv) return AppScaffold(body: form);

    // TV: typing a password with the remote is painful, so the QR sign-in
    // sits next to the form and gets focus first.
    return AppScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 24, 48, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: const LoginWelcomeIntro(compact: true),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                const Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: TvQrLoginPanel(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 60,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: VerticalDivider(
                          color: context.palette.textSecondary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: VerticalDivider(
                          color: context.palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: form),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
