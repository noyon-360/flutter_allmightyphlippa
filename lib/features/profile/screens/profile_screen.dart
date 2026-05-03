import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/constants/app_colors.dart';
import 'package:flutter_almightyflippa/core/constants/assest_const.dart'
    hide Icons;
import 'package:flutter_almightyflippa/core/utils/app_svg.dart';
import 'package:flutter_almightyflippa/features/playlist/screens/playlist_list_screen.dart';
import 'package:flutter_almightyflippa/features/profile/controller/profile_controller.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import 'package:flutter_almightyflippa/features/playlist/models/server_request_model.dart';
import 'package:flutter_almightyflippa/features/video/screens/video_play_screen.dart';

import '../../../core/common/widgets/app_cached_image.dart';
import '../../../core/common/widgets/button_widgets.dart';
import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../auth/controller/auth_controller.dart';
import '../../favourites/screens/favourite_screen.dart';
import '../../history/screens/history_screen.dart';
import '../../app/screens/about_app_screen.dart';
import '../../app/screens/privacy_policy_screen.dart';
import '../../app/screens/terms_condition_screen.dart';
import '../../auth/screens/change_password_screen.dart';
import '../../subscription/screens/subscription_screen.dart';
import 'profile_update_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.put(ProfileController());

    return RefreshIndicator.adaptive(
      onRefresh: () => profileCtrl.refreshProfile(),

      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gap.h24,
              Text(
                "My Profile",
                style: TextStyle(
                  color: AppColors.primaryWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gap.h24,

              // Profile Header
              Obx(() {
                final user = profileCtrl.userProfile.value;
                return Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: (user?.avatar?.url?.isNotEmpty ?? false)
                          ? AppCachedImage(
                              imageUrl: user!.avatar!.url!,
                              width: 80,
                              height: 80,
                              borderRadius: BorderRadius.circular(12),
                              fit: BoxFit.cover,
                              shimmerBaseColor: AppColors.containerBgColor,
                              shimmerHighlightColor: AppColors.containerBgColor,
                              onTap: () {},
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/splash_and_login_logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                    Gap.w16,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? "",
                            style: TextStyle(
                              color: AppColors.primaryWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.email ?? "",
                            style: TextStyle(
                              color: AppColors.primaryGray,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Get.to(
                          () => const ProfileUpdateScreen(),
                          transition: Transition.rightToLeft,
                        );
                      },
                      icon: AppSvg(
                        asset: AssetsConstants.icons.edit05,
                        color: AppColors.primaryWhite,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ],
                );
              }),

              Gap.h32,

              // History Section
              Obx(() {
                if (profileCtrl.watchHistory.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "History",
                          style: TextStyle(
                            color: AppColors.primaryWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Get.to(() => const HistoryScreen());
                          },
                          child: Text(
                            "See All",
                            style: TextStyle(color: AppColors.primaryGray),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: profileCtrl.watchHistory.length,
                        separatorBuilder: (context, index) => Gap.w12,
                        itemBuilder: (context, index) {
                          final history = profileCtrl.watchHistory[index];
                          return TvFocusWrapper(
                            onTap: () {
                              final streamId = int.tryParse(history.videoId);
                              final type = history.videoType == 'movie'
                                  ? ServerType.movies
                                  : history.videoType == 'series'
                                  ? ServerType.series
                                  : null;

                              if (streamId != null && type != null) {
                                Get.to(
                                  () => VideoPlayScreen(
                                    streamId: streamId,
                                    type: type,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        children: [
                                          if (history.thumbnail.isNotEmpty)
                                            Positioned.fill(
                                              child: AppCachedImage(
                                                imageUrl: history.thumbnail,
                                                fit: BoxFit.cover,
                                                shimmerBaseColor:
                                                    AppColors.containerBgColor,
                                                shimmerHighlightColor:
                                                    AppColors.containerBgColor,
                                                onTap: () {},
                                              ),
                                            )
                                          else
                                            Positioned.fill(
                                              child: Container(
                                                color:
                                                    AppColors.containerBgColor,
                                                child: const Icon(
                                                  Icons.movie,
                                                  color: AppColors.iconColor,
                                                  size: 40,
                                                ),
                                              ),
                                            ),

                                          // Linear Progress Bar
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: LinearProgressIndicator(
                                              value:
                                                  history.progressPercentage /
                                                  100,
                                              backgroundColor: Colors.black26,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(AppColors.red),
                                              minHeight: 3,
                                            ),
                                          ),

                                          // Series Badge
                                          if (history.videoType == 'series')
                                            Positioned(
                                              top: 8,
                                              left: 8,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  "S${history.seasonNumber} E${history.episodeNumber}",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Gap.h8,
                                  Text(
                                    history.name ?? 'Unknown',
                                    style: const TextStyle(
                                      color: AppColors.primaryWhite,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    history.videoType == 'movie'
                                        ? 'Movie'
                                        : 'Series',
                                    style: const TextStyle(
                                      color: AppColors.primaryGray,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Gap.h24,
                  ],
                );
              }),

              // Menu Items
              _buildMenuItem(
                iconAsset: '', // Using Material Icon
                title: "Subscription",
                isSvg: false,
                iconData: Icons.stars,
                iconColor: Colors.amber,
                onTap: () {
                  Get.to(
                    () => const SubscriptionScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
              _buildMenuItem(
                iconAsset: AssetsConstants.icons.favourite,
                title: "Favourite",
                onTap: () {
                  Get.to(
                    () => const FavouriteScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
              _buildMenuItem(
                iconAsset: AssetsConstants.icons.playSquare,
                title: "Playlist",
                onTap: () {
                  Get.to(
                    () => const PlaylistListScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
              _buildMenuItem(
                iconAsset: AssetsConstants.icons.lock,
                title: "Change Password",
                onTap: () {
                  Get.to(
                    () => const ChangePasswordScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
              _buildMenuItem(
                iconAsset: AssetsConstants.icons.chartBreakoutCircle,
                title: "About App",
                onTap: () {
                  Get.to(
                    () => const AboutAppScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
              _buildMenuItem(
                iconAsset: AssetsConstants.icons.fileShield,
                title: "Privacy Policy",
                onTap: () {
                  Get.to(
                    () => const PrivacyPolicyScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
              _buildMenuItem(
                iconAsset: AssetsConstants.icons.shieldOff,
                title: "Term & Condition",
                isSvg: false,
                onTap: () {
                  Get.to(
                    () => const TermsConditionScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
              _buildMenuItem(
                iconAsset: AssetsConstants.icons.trash,
                title: "Delete Account",
                onTap: () {
                  Get.dialog(
                    Dialog(
                      backgroundColor: AppColors.containerBgColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Delete Account",
                              style: TextStyle(
                                color: AppColors.primaryWhite,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Gap.h16,
                            const Text(
                              "Are you sure you want to delete your account? This action is permanent and cannot be undone.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.primaryGray,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            Gap.h32,
                            Row(
                              children: [
                                Expanded(
                                  child: PrimaryButton(
                                    text: "Delete",
                                    height: 45,
                                    borderRadius: 45,
                                    backgroundColor: AppColors.red,
                                    textColor: Colors.white,
                                    onSimplePressed: () {
                                      Get.put(AuthController()).deleteAccount();
                                      Get.back();
                                    },
                                  ),
                                ),
                                Gap.w16,
                                Expanded(
                                  child: SecondaryButton(
                                    text: "Cancel",
                                    height: 45,
                                    borderRadius: 45,
                                    onSimplePressed: () => Get.back(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                iconAsset: AssetsConstants.icons.logOut,
                title: "Log Out",
                titleColor: AppColors.red,
                iconColor: AppColors.red,
                onTap: () {
                  Get.dialog(
                    Dialog(
                      backgroundColor: AppColors.containerBgColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Confirm Logout",
                              style: TextStyle(
                                color: AppColors.primaryWhite,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Gap.h16,
                            const Text(
                              "Are you sure you want to log out of your account?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.primaryGray,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            Gap.h32,
                            Row(
                              children: [
                                Expanded(
                                  child: SecondaryButton(
                                    text: "Cancel",
                                    height: 45,
                                    borderRadius: 45,
                                    onSimplePressed: () => Get.back(),
                                  ),
                                ),
                                Gap.w16,
                                Expanded(
                                  child: PrimaryButton(
                                    text: "Logout",
                                    height: 45,
                                    borderRadius: 45,
                                    backgroundColor: AppColors.red,
                                    textColor: Colors.white,
                                    onSimplePressed: () {
                                      Get.back();
                                      profileCtrl.logout();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Gap.h40,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String iconAsset,
    required String title,
    required VoidCallback onTap,
    bool isSvg = true,
    IconData? iconData,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: iconData != null
              ? Icon(iconData, color: iconColor ?? AppColors.primaryWhite, size: 24)
              : isSvg
                  ? AppSvg(
                      asset: iconAsset,
                      color: iconColor ?? AppColors.primaryWhite,
                      width: 24,
                      height: 24,
                    )
                  : Image.asset(
                      iconAsset,
                      color: iconColor ?? AppColors.primaryWhite,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
          title: Text(
            title,
            style: TextStyle(
              color: titleColor ?? AppColors.primaryWhite,
              fontSize: 16,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.primaryGray,
            size: 16,
          ),
          onTap: onTap,
        ),
        const Divider(color: AppColors.containerBgColor, height: 1),
      ],
    );
  }
}
