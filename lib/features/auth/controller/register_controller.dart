import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/features/auth/models/register_request_model.dart';
import 'package:flutter_almightyflippa/features/auth/repo/auth_repo.dart';
import 'package:get/get.dart';
import 'package:flutx_core/flutx_core.dart';

import '../../../core/services/auth_storage_service.dart';
import '../../playlist/screens/playlist_list_screen.dart';

class RegisterController extends GetxController {
  final AuthRepo _authRepo = Get.find<AuthRepo>();
  final AuthStorageService _authStorageService = Get.find<AuthStorageService>();

  // TextControllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // FocusNodes
  final nameFocus = FocusNode();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();
  final signUpButtonFocus = FocusNode();

  // Form Key
  final registerFormKey = GlobalKey<FormState>();

  // States
  // final RxBool isLoading = false.obs;
  final RxString registerErrorMessage = "".obs;
  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;
  final RxBool agreeToTerms = false.obs;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    signUpButtonFocus.dispose();
    super.onClose();
  }

  void toggleObscurePassword() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleObscureConfirmPassword() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  void toggleAgreeToTerms() {
    agreeToTerms.value = !agreeToTerms.value;
  }

  Future<void> register() async {
    // if (isLoading.value) return;

    if (registerFormKey.currentState?.validate() ?? false) {
      if (!agreeToTerms.value) {
        Get.snackbar('Error', 'Please agree to Terms & Conditions');
        return;
      }

      registerErrorMessage.value = "";
      // isLoading.value = true;

      final request = RegisterRequestModel(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        confirmPassword: confirmPasswordController.text,
      );

      final result = await _authRepo.register(request);

      result.fold(
        (fail) {
          // isLoading.value = false;
          registerErrorMessage.value = fail.message;
          DPrint.log("Registration Fail : ${fail.message}");
        },
        (success) {
          final data = success.data;
          _authStorageService.storeAuthData(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken,
            role: data.role,
            userId: data.id ?? '',
          );

          Get.to(() => const PlaylistListScreen());
        },
      );
    }
  }
}
