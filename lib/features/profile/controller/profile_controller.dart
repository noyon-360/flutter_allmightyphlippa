import 'package:flutx_core/core/debug_print.dart';
import 'package:get/get.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../auth/models/user_response_model.dart';
import '../../auth/screens/login_screen.dart';
import '../repo/profile_repo.dart';

class ProfileController extends GetxController {
  final ProfileRepo _profileRepo;
  final AuthStorageService _authStorageService;

  ProfileController(this._profileRepo, this._authStorageService);

  final Rxn<UserModel> userProfile = Rxn<UserModel>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    getProfile();
  }

  Future<void> getProfile() async {
    isLoading.value = true;
    final result = await _profileRepo.getProfile();
    result.fold(
      (failure) {
        // Handle failure if needed, for now just log
        DPrint.error("Error fetching profile: ${failure.message}");
      },
      (success) {
        userProfile.value = success.data;
      },
    );
    isLoading.value = false;
  }

  Future<void> logout() async {
    await _authStorageService.clearAuthData();
    Get.offAll(() => const LoginScreen());
  }
}
