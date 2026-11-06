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
import 'package:flutter_almightyflippa/features/video/screens/live_video_play_screen.dart';
import 'package:flutter_almightyflippa/features/video/screens/video_play_screen.dart';
import '../../../core/services/watch_history_service.dart';
import '../../epg/screens/epg_reminders_screen.dart';
import '../../epg/services/epg_timeline_cache.dart';
import '../../epg/services/live_tv_now_playing_cache.dart';
import '../../tv/controllers/live_tv_controller.dart';

import '../../../core/common/widgets/app_cached_image.dart';
import '../../../core/common/widgets/button_widgets.dart';
import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/utils/tv_device.dart';
import '../../auth/controller/auth_controller.dart';
import '../../favourites/screens/favourite_screen.dart';
import '../../watch_later/screens/watch_later_screen.dart';
import '../../parental/screens/parental_lock_screen.dart';
import '../../../core/services/parental_lock_service.dart';
import '../../history/screens/history_screen.dart';
import '../../app/screens/about_app_screen.dart';
import '../../app/screens/privacy_policy_screen.dart';
import '../../app/screens/terms_condition_screen.dart';
import '../../auth/screens/change_password_screen.dart';
import '../../auth/screens/tv_login_approve_screen.dart';
import '../../downloads/screens/downloads_screen.dart';
import '../../subscription/screens/subscription_screen.dart';
import '../widgets/theme_picker_dialog.dart';
import 'profile_update_screen.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// How many channels "Update EPG" refetches up front — one request each,
  /// so it stays around a screenful (see [LiveTvNowPlayingCache]).
  static const _epgUpdateChannelLimit = 20;

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.put(ProfileController());
    final watchHistoryService = Get.find<WatchHistoryService>();

    return RefreshIndicator.adaptive(
      onRefresh: () => profileCtrl.refreshProfile(),

      child: SingleChildScrollView(
        // Clear of the floating nav bar.
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gap.h24,
              Text(
                "My Profile",
                style: TextStyle(
                  color: context.palette.textPrimary,
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
                              shimmerBaseColor: context.palette.surface,
                              shimmerHighlightColor: context.palette.surface,
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
                              color: context.palette.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.email ?? "",
                            style: TextStyle(
                              color: context.palette.textSecondary,
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
                        color: context.palette.textPrimary,
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
                if (watchHistoryService.watchHistory.isEmpty) {
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
                            color: context.palette.textPrimary,
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
                            style: TextStyle(
                              color: context.palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: watchHistoryService.watchHistory.length,
                        separatorBuilder: (context, index) => Gap.w12,
                        itemBuilder: (context, index) {
                          final history =
                              watchHistoryService.watchHistory[index];
                          return TvFocusWrapper(
                            onTap: () {
                              final streamId = int.tryParse(history.videoId);
                              if (streamId == null) return;

                              if (history.videoType == 'live') {
                                Get.to(
                                  () => LiveVideoPlayScreen(
                                    streamId: streamId,
                                    channelName: history.name ?? 'Live TV',
                                    channelLogo: history.thumbnail,
                                  ),
                                );
                                return;
                              }

                              final type = history.videoType == 'movie'
                                  ? ServerType.movies
                                  : history.videoType == 'series'
                                  ? ServerType.series
                                  : null;

                              if (type != null) {
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
                                                    context.palette.surface,
                                                shimmerHighlightColor:
                                                    context.palette.surface,
                                                onTap: () {},
                                              ),
                                            )
                                          else
                                            Positioned.fill(
                                              child: Container(
                                                color: context.palette.surface,
                                                child: Icon(
                                                  Icons.movie,
                                                  color: context
                                                      .palette
                                                      .textPrimary,
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
                                    style: TextStyle(
                                      color: context.palette.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    history.videoType == 'movie'
                                        ? 'Movie'
                                        : history.videoType == 'live'
                                        ? 'Live TV'
                                        : 'Series',
                                    style: TextStyle(
                                      color: context.palette.textSecondary,
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
                context,
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
              // No downloads on TV (little storage, nowhere to watch offline).
              if (!TvDevice.isTv)
                _buildMenuItem(
                  context,
                  iconAsset: '',
                  isSvg: false,
                  iconData: Icons.download_for_offline_outlined,
                  iconColor: Colors.blueAccent,
                  title: "Downloads",
                  onTap: () {
                    Get.to(
                      () => const DownloadsScreen(),
                      transition: Transition.rightToLeft,
                    );
                  },
                ),
              _buildMenuItem(
                context,
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
                context,
                iconAsset: '',
                isSvg: false,
                iconData: Icons.bookmark_border,
                title: "Watch Later",
                onTap: () {
                  Get.to(
                    () => const WatchLaterScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
              _buildMenuItem(
                context,
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
                context,
                iconAsset: '',
                iconData: Icons.notifications_active_outlined,
                title: "My Alerts",
                onTap: () {
                  Get.to(
                    () => const EpgRemindersScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
              _buildMenuItem(
                context,
                iconAsset: '',
                iconData: Icons.refresh,
                title: "Update EPG",
                onTap: _updateEpg,
              ),
              // A TV can't scan its own QR code; this is the phone side.
              if (!TvDevice.isTv)
                _buildMenuItem(
                  context,
                  iconAsset: '',
                  iconData: Icons.connected_tv,
                  title: "Sign in on a TV",
                  onTap: () {
                    Get.to(
                      () => const TvLoginApproveScreen(),
                      transition: Transition.rightToLeft,
                    );
                  },
                ),
              _buildMenuItem(
                context,
                iconAsset: '',
                iconData: Icons.brightness_6_outlined,
                title: "Appearance",
                onTap: showThemePickerDialog,
              ),
              _buildMenuItem(
                context,
                iconAsset: '',
                iconData: Icons.family_restroom,
                title: "Parental Lock",
                onTap: () async {
                  // Only the parent may change the locks.
                  if (!await ParentalLockService.to.verifyParent()) return;
                  Get.to(
                    () => const ParentalLockScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
              _buildMenuItem(
                context,
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
                context,
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
                context,
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
                context,
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
                context,
                iconAsset: AssetsConstants.icons.trash,
                title: "Delete Account",
                onTap: () {
                  Get.dialog(
                    Dialog(
                      backgroundColor: context.palette.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Delete Account",
                              style: TextStyle(
                                color: context.palette.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Gap.h16,
                            Text(
                              "Are you sure you want to delete your account? This action is permanent and cannot be undone.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.palette.textSecondary,
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
                context,
                iconAsset: AssetsConstants.icons.logOut,
                title: "Log Out",
                titleColor: AppColors.red,
                iconColor: AppColors.red,
                onTap: () {
                  Get.dialog(
                    Dialog(
                      backgroundColor: context.palette.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Confirm Logout",
                              style: TextStyle(
                                color: context.palette.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Gap.h16,
                            Text(
                              "Are you sure you want to log out of your account?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.palette.textSecondary,
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

  /// Drops the cached guide and refetches it for the channels already in the
  /// Live TV list, so the result shown is that of a real fetch. Other
  /// channels load fresh as they come into view, same as [LiveTvNowPlayingCache]
  /// always does — EPG is per channel, so the whole catalog can't be fetched.
  Future<void> _updateEpg() async {
    Get.dialog(
      const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator(color: AppColors.red)),
      ),
      barrierDismissible: false,
    );

    final nowPlaying = Get.find<LiveTvNowPlayingCache>();
    Get.find<EpgTimelineCache>().clear();
    nowPlaying.clear();

    final streamIds = Get.find<LiveTvController>().liveTvList
        .take(_epgUpdateChannelLimit)
        .map((channel) => channel.streamId)
        .toList();
    await Future.wait(streamIds.map(nowPlaying.ensureLoaded));

    Get.back();

    final failed =
        streamIds.isNotEmpty && streamIds.every(nowPlaying.hasFailed);
    Get.snackbar(
      'EPG',
      failed
          ? 'Could not update the TV guide. Please try again.'
          : 'TV guide updated.',
      backgroundColor: failed ? Colors.red : Colors.green,
      colorText: Colors.white,
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
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
              ? Icon(
                  iconData,
                  color: iconColor ?? context.palette.textPrimary,
                  size: 24,
                )
              : isSvg
              ? AppSvg(
                  asset: iconAsset,
                  color: iconColor ?? context.palette.textPrimary,
                  width: 24,
                  height: 24,
                )
              : Image.asset(
                  iconAsset,
                  color: iconColor ?? context.palette.textPrimary,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
          title: Text(
            title,
            style: TextStyle(
              color: titleColor ?? context.palette.textPrimary,
              fontSize: 16,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: context.palette.textSecondary,
            size: 16,
          ),
          onTap: onTap,
        ),
        Divider(color: context.palette.surface, height: 1),
      ],
    );
  }
}
