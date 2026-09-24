import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_almightyflippa/core/constants/app_colors.dart';
import 'package:flutter_almightyflippa/core/constants/assest_const.dart';
import '../../home/screens/home_screen.dart';
import '../../movie/screens/movie_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../series/screens/series_screen.dart';
import '../../tv/screens/live_tv_screen.dart';
import '../controllers/bottom_nav_controller.dart';
import '../widgets/floating_nav_bar.dart';

class BottomNavScreen extends StatelessWidget {
  const BottomNavScreen({super.key});

  static final List<FloatingNavItem> _items = [
    FloatingNavItem(icon: AssetsConstants.icons.home, label: 'Home'),
    FloatingNavItem(icon: AssetsConstants.icons.playSquare, label: 'Live TV'),
    FloatingNavItem(icon: AssetsConstants.icons.movieOutline, label: 'Movies'),
    FloatingNavItem(icon: AssetsConstants.icons.series, label: 'Series'),
    FloatingNavItem(
      icon: AssetsConstants.icons.userCircle,
      label: 'My Profile',
    ),
  ];

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

    return Scaffold(
      // The bar floats over the content; the Scaffold reports its height in
      // MediaQuery.padding.bottom so each tab pads its scrolling content clear
      // of it.
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Obx(() => pages[controller.selectedIndex.value]),
        ),
      ),
      bottomNavigationBar: Obx(
        () => FloatingNavBar(
          items: _items,
          selectedIndex: controller.selectedIndex.value,
          onSelected: controller.changeIndex,
        ),
      ),
    );
  }
}
