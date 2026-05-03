import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_almightyflippa/core/common/widgets/app_scaffold.dart';
import 'package:flutter_almightyflippa/core/constants/app_colors.dart';
import 'package:flutter_almightyflippa/core/utils/app_svg.dart';
import 'package:flutter_almightyflippa/core/constants/assest_const.dart';
import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../home/screens/home_screen.dart';
import '../../movie/screens/movie_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../series/screens/series_screen.dart';
import '../../tv/screens/live_tv_screen.dart';
import '../controllers/bottom_nav_controller.dart';

class BottomNavScreen extends StatelessWidget {
  const BottomNavScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BottomNavController());

    final List<Widget> pages = [
      const HomeScreen(),
      const LiveTvScreen(),
      const MovieScreen(),
      const SeriesScreen(),
      const ProfileScreen(),
    ];

    return AppScaffold(
      removePadding: true,
      body: Obx(() => pages[controller.selectedIndex.value]),
      bottomNavigationBar: Obx(() {
        return SafeArea(
          child: Container(
            height: 70,
            decoration: const BoxDecoration(
              color: AppColors.primaryBlack,
              border: Border(
                top: BorderSide(color: Color(0xFF272727), width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: AssetsConstants.icons.home,
                  label: 'Home',
                  controller: controller,
                ),
                _buildNavItem(
                  index: 1,
                  icon: AssetsConstants.icons.playSquare,
                  label: 'Live TV',
                  controller: controller,
                ),
                _buildNavItem(
                  index: 2,
                  icon: AssetsConstants.icons.movieOutline,
                  label: 'Movies',
                  controller: controller,
                ),
                _buildNavItem(
                  index: 3,
                  icon: AssetsConstants.icons.series,
                  label: 'Series',
                  controller: controller,
                ),
                _buildNavItem(
                  index: 4,
                  icon: AssetsConstants.icons.userCircle,
                  label: 'My Profile',
                  controller: controller,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String icon,
    required String label,
    required BottomNavController controller,
  }) {
    final isSelected = controller.selectedIndex.value == index;
    return TvFocusWrapper(
      onTap: () => controller.changeIndex(index),
      // behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicator line above
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryWhite : Colors.transparent,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AppSvg(
            asset: icon,
            width: 24,
            height: 24,
            color: isSelected ? AppColors.primaryWhite : AppColors.primaryGray,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected
                  ? AppColors.primaryWhite
                  : AppColors.primaryGray,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
