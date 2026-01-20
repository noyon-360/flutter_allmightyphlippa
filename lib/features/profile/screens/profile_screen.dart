import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/common/widgets/app_scaffold.dart';
import 'package:flutter_almightyflippa/core/constants/app_colors.dart';
import 'package:flutter_almightyflippa/core/constants/assest_const.dart'
    hide Icons;
import 'package:flutter_almightyflippa/core/utils/app_svg.dart';
import 'package:flutter_almightyflippa/features/profile/controller/profile_controller.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.put(ProfileController(Get.find(), Get.find()));

    return AppScaffold(
      body: SingleChildScrollView(
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
                      image: DecorationImage(
                        image: user?.avatar?.url != null
                            ? NetworkImage(user!.avatar!.url!)
                            : const AssetImage(
                                    'assets/images/splash_and_login_logo.png',
                                  )
                                  as ImageProvider,
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
                          user?.name ?? "Ross Geller",
                          style: TextStyle(
                            color: AppColors.primaryWhite,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.email ?? "ross@gmail.com",
                          style: TextStyle(
                            color: AppColors.primaryGray,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
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

            /*
            // History Section (Commented out for now)
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
                  onPressed: () {},
                  child: Text(
                    "See All",
                    style: TextStyle(color: AppColors.primaryGray),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (context, index) => Gap.w12,
                itemBuilder: (context, index) {
                  return Container(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Image.network(
                                "https://via.placeholder.com/150x100",
                                height: 100,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Text(
                                  "15:43 / 40:15",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    backgroundColor: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Gap.h8,
                        Text(
                          "Lorem ipsum dolor sit amet, consectetur ....",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.primaryWhite,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Gap.h24,
            */

            // Menu Items
            _buildMenuItem(
              iconAsset: AssetsConstants.icons.favourite,
              title: "Favourite",
              onTap: () {},
            ),
            _buildMenuItem(
              iconAsset: AssetsConstants.icons.lock,
              title: "Change Password",
              onTap: () {},
            ),
            _buildMenuItem(
              iconAsset: AssetsConstants.icons.chartBreakoutCircle,
              title: "About App",
              onTap: () {},
            ),
            _buildMenuItem(
              iconAsset: AssetsConstants.icons.fileShield,
              title: "Privacy Policy",
              onTap: () {},
            ),
            _buildMenuItem(
              iconAsset: AssetsConstants.icons.shieldOff,
              title: "Term & Condition",
              isSvg: false,
              onTap: () {},
            ),
            _buildMenuItem(
              iconAsset: AssetsConstants.icons.logOut,
              title: "Log Out",
              titleColor: AppColors.red,
              iconColor: AppColors.red,
              onTap: () => profileCtrl.logout(),
            ),
            Gap.h40,
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String iconAsset,
    required String title,
    required VoidCallback onTap,
    bool isSvg = true,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: isSvg
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
