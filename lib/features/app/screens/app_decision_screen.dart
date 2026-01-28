import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/features/playlist/screens/playlist_list_screen.dart';
import '/core/common/widgets/app_logo.dart';
import '/core/constants/assest_const.dart';
import '/features/auth/screens/welcome_screen.dart';
import 'package:get/get.dart';
import '../../bottom_nav/screens/bottom_nav_screen.dart';
import '../../playlist/models/playlist_data.dart';

import '/core/constants/key_constants.dart';

import '/core/services/auth_storage_service.dart';
import '/core/services/secure_store_services.dart';
import '/features/auth/screens/login_screen.dart';

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
          final PlaylistData playlistData = await _authStorageService
              .getPlaylistData();

          if (playlistData.isNotEmpty) {
            Get.offAll(
              () => const BottomNavScreen(),
              transition: Transition.fadeIn,
            );
          } else {
            Get.offAll(
              () => const PlaylistListScreen(),
              transition: Transition.fadeIn,
            );
          }
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
          child: AppLogo(
            height: 120,
            width: 120,
            images: AssetsConstants.images.logo,
            borderRadius: 22,
          ),
        ),
      ),
    );
  }
}