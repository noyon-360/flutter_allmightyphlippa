import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/common/widgets/app_logo.dart';
import 'package:flutter_almightyflippa/core/constants/assest_const.dart';
import '../../bottom_nav/screens/bottom_nav_screen.dart';
import '/features/auth/screens/welcome_screen.dart';
import 'package:get/get.dart';

import '../../../core/constants/key_constants.dart';

import '../../../core/services/auth_storage_service.dart';
import '../../../core/services/secure_store_services.dart';
import '../../auth/screens/login_screen.dart';

class AppDecisionScreen extends StatefulWidget {
  const AppDecisionScreen({super.key});

  @override
  State<AppDecisionScreen> createState() => _AppDecisionScreenState();
}

class _AppDecisionScreenState extends State<AppDecisionScreen> {
  final SecureStoreServices _secureStore = SecureStoreServices();
  final AuthStorageService _authStorageService = AuthStorageService();

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final onboardingDone = await _secureStore.retrieveData(
      KeyConstants.onboardingStatus,
    );

    if (mounted) {
      if (onboardingDone == "true") {
        final bool isAuth = await _authStorageService.isAuthenticated();

        if (isAuth) {
          Get.offAll(() => BottomNavScreen(), transition: Transition.fadeIn);
        } else {
          Get.offAll(() => const LoginScreen(), transition: Transition.fadeIn);
        }
      } else {
        Get.offAll(() => const WelcomeScreen(), transition: Transition.fadeIn);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
          child: AppLogo(images: AssetsConstants.images.logo),
        ),
      ),
    );
  }
}
