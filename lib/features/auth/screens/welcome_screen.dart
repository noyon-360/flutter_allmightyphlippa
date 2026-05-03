import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/common/widgets/button_widgets.dart';
import 'package:flutter_almightyflippa/core/constants/key_constants.dart';
import 'package:get/get.dart';

import '../../../core/constants/assest_const.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/secure_store_services.dart';
import '../../../core/common/widgets/tv_focus_wrapper.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static final String _backgroundImage =
      AssetsConstants.images.appLogoLandscape;
  static const int _pageCount = 3;

  @override
  Widget build(BuildContext context) {
    final PageController pageController = PageController();
    final ValueNotifier<int> currentPage = ValueNotifier<int>(0);
    final SecureStoreServices secureStore = SecureStoreServices();

    // Update current page for dots and parallax
    pageController.addListener(() {
      final int page = (pageController.page ?? 0).round();
      if (currentPage.value != page) {
        currentPage.value = page;
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // 1. Animated background with subtle parallax effect
          ValueListenableBuilder<int>(
            valueListenable: currentPage,
            builder: (context, page, _) {
              final double offset =
                  (pageController.hasClients && pageController.page != null)
                  ? pageController.page! - page
                  : 0.0;

              return OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Transform.scale(
                  scale: 1.25,
                  child: Transform.translate(
                    offset: Offset(
                      offset * 120,
                      0,
                    ), // Adjust for desired parallax strength
                    child: Image.asset(
                      _backgroundImage,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color.fromRGBO(0, 0, 0, 0.4),
                    Color.fromRGBO(0, 0, 0, 0.8),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 3. Text and page indicators (non-interactive text, interactive dots)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 40.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Non-interactive welcome text
                  IgnorePointer(
                    ignoring: true,
                    child: Column(
                      children: const [
                        Text(
                          'Welcome to LABBY TV',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primaryWhite,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'The best video player app of the century to entertain you every day',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primaryWhite,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Page dots (interactive)
                  ValueListenableBuilder<int>(
                    valueListenable: currentPage,
                    builder: (context, page, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pageCount, (i) {
                          final bool active = i == page;
                          return TvFocusWrapper(
                            onTap: () {
                              pageController.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: active ? 30 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primaryWhite
                                    : AppColors.primaryGray,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),

                  const SizedBox(height: 80), // Space for the button below
                ],
              ),
            ),
          ),

          // 4. Transparent PageView for capturing horizontal swipes
          PageView.builder(
            controller: pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: _pageCount,
            itemBuilder: (context, index) => const SizedBox.expand(),
          ),

          // 5. "Get Started" button — placed on TOP so it's clickable
          Positioned(
            left: 18.0,
            right: 18.0,
            bottom: 60.0, // Adjust if needed for safe area or design
            child: PrimaryButton(
              onSimplePressed: () async {
                await secureStore.storeData(
                  KeyConstants.onboardingStatus,
                  'true',
                );
                
                Get.off(
                  () => const LoginScreen(),
                  transition: Transition.rightToLeft,
                );
              },
              text: "Get Started",
            ),
          ),
        ],
      ),
    );
  }
}
