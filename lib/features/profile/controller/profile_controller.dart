import 'package:flutter_almightyflippa/core/services/multiple_form_data_manager.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/network_stream.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/services/revenuecat_service.dart';
import '../../auth/models/user_response_model.dart';
import '../../auth/screens/login_screen.dart';
import '../../../core/services/watch_history_service.dart';
import '../repo/profile_repo.dart';

class ProfileController extends GetxController {
  final _profileRepo = Get.find<ProfileRepo>();
  final AuthStorageService _authStorageService = AuthStorageService();

  final Rxn<UserModel> userProfile = Rxn<UserModel>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Keep the global premium flag in sync with every profile load/refresh.
    // Registered here (not in PremiumService) because this controller is
    // lazily created and can be recreated, which would orphan a listener.
    ever(userProfile, (_) {
      if (Get.isRegistered<PremiumService>()) PremiumService.to.refresh();
    });
    getProfile();
  }

  Future<void> refreshProfile() async {
    getProfile(isRefresh: true);
    if (Get.isRegistered<WatchHistoryService>()) {
      Get.find<WatchHistoryService>().refreshList();
    }
  }

  Future<void> getProfile({bool isRefresh = false}) async {
    return _profileRepo
        .getProfile(forceRefresh: isRefresh)
        .bind(rx: userProfile, loading: isLoading);
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    XFile? avatar,
  }) async {
    final multipartData = MultiFormDataManager();

    multipartData.addTextData('name', name ?? '');
    multipartData.addTextData('email', email ?? '');
    if (avatar != null) {
      multipartData.addFile(key: 'avatar', file: avatar);
    }

    final requestdata = await multipartData.toFormDataAsync();
    try {
      await _profileRepo
          .updateProfile(formData: requestdata)
          .asStream()
          .bind(rx: userProfile, loading: isLoading);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    if (Get.isRegistered<NotificationService>()) {
      await Get.find<NotificationService>().onUserLogout();
    }
    // Detach the purchase account first so the next user on this device
    // doesn't inherit this user's subscription.
    if (Get.isRegistered<RevenueCatService>()) {
      await Get.find<RevenueCatService>().logoutUser();
    }
    await _authStorageService.clearAuthData();
    userProfile.value = null;
    Get.offAll(() => const LoginScreen());
  }
}
