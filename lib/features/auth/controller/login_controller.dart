import 'package:flutter/material.dart';
import '/features/playlist/screens/playlist_list_screen.dart';
import '/core/services/auth_storage_service.dart';
import '/features/auth/models/login_request_model.dart';
import '/features/auth/repo/auth_repo.dart';
import 'package:get/get.dart';
import 'package:flutx_core/flutx_core.dart';

class LoginController extends GetxController {
  final AuthRepo _authRepo = Get.find<AuthRepo>();
  final AuthStorageService _authStorageService = Get.find<AuthStorageService>();

  // TextControllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // FocusNodes
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final loginButtonFocus = FocusNode();

  // Form Key
  final loginFormKey = GlobalKey<FormState>();

  // States
  final RxString loginErrorMessage = "".obs;
  final RxBool obscurePassword = true.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    loginButtonFocus.dispose();
    super.onClose();
  }

  void toggleObscurePassword() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> login() async {
    if (loginFormKey.currentState?.validate() ?? false) {
      loginErrorMessage.value = "";

      final request = LoginRequestModel(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final result = await _authRepo.login(request);

      result.fold(
        (fail) {
          loginErrorMessage.value = fail.message;
          DPrint.log("Login Fail : ${fail.message}");
        },
        (success) async {
          final data = success.data;
          await _authStorageService.storeAuthData(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken,
            role: data.role,
            userId: data.user?.id ?? '',
          );

          Get.to(() => const PlaylistListScreen());
        },
      );
    }
  }
}
