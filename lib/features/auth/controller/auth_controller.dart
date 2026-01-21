// import '../../../core/services/auth_storage_service.dart';
// import '/features/auth/repo/auth_repo.dart';
// import 'package:get/get.dart';

// import 'package:flutter_almightyflippa/features/auth/controller/login_controller.dart';
// import 'package:flutter_almightyflippa/features/auth/controller/register_controller.dart';

// class AuthController extends GetxController {
//   // Master Controller for Auth

//   @override
//   void onInit() {
//     super.onInit();
//     Get.put(AuthRepo());
//     Get.put(AuthStorageService());
//     Get.put(LoginController());
//     Get.put(RegisterController());
//   }

//   // Shared States could go here (e.g., currentUser)
//   final RxString authErrorMessage = "".obs;

//   @override
//   void onClose() {
//     loginCtrl.dispose();
//     registerCtrl.dispose();
//     super.onClose();
//   }
// }
