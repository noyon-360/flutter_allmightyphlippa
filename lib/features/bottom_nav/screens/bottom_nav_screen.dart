import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_almightyflippa/core/constants/assest_const.dart';
import 'package:flutter_almightyflippa/core/utils/tv_device.dart';
import '../../home/screens/home_screen.dart';
import '../../movie/screens/movie_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../series/screens/series_screen.dart';
import '../../tv/screens/live_tv_screen.dart';
import '../controllers/bottom_nav_controller.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/tv_nav_rail.dart';

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

    // Phones keep exiting from any tab, as before (and get the same widget
    // tree as before — an Obx that reads nothing throws in GetX).
    if (!TvDevice.isTv) return _buildScaffold(controller, pages);

    // TV: Back on any other tab goes to Home first; Back on Home leaves the
    // app.
    return Obx(
      () => PopScope(
        canPop: controller.selectedIndex.value == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.changeIndex(0);
        },
        child: _buildScaffold(controller, pages),
      ),
    );
  }

  Widget _buildScaffold(BottomNavController controller, List<Widget> pages) {
    if (TvDevice.isTv) return _buildTvScaffold(controller, pages);
    return Scaffold(
      // The bar floats over the content; the Scaffold reports its height in
      // MediaQuery.padding.bottom so each tab pads its scrolling content clear
      // of it.
      // Not on TV: there the remote scrolls the focused item into the
      // visible area, which would otherwise include the strip behind the bar
      // and leave the focused item hidden under it.
      extendBody: !TvDevice.isTv,
      body: SafeArea(
        bottom: false,
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Obx(() => pages[controller.selectedIndex.value]),
          ),
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

  /// TV: a navigation rail on the left instead of the phone's bottom bar.
  Widget _buildTvScaffold(BottomNavController controller, List<Widget> pages) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => TvNavRail(
              items: _items,
              selectedIndex: controller.selectedIndex.value,
              onSelected: controller.changeIndex,
            ),
          ),
          Expanded(
            // The rail already covers the left edge, so only the top, right
            // and bottom need the overscan-safe margin.
            child: SafeArea(
              left: false,
              child: Builder(
                builder: (context) => MediaQuery.removePadding(
                  context: context,
                  removeLeft: true,
                  removeTop: true,
                  child: Obx(() => pages[controller.selectedIndex.value]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
