import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_svg.dart';

/// One tab of the [FloatingNavBar].
class FloatingNavItem {
  final String icon;
  final String label;

  const FloatingNavItem({required this.icon, required this.label});
}

/// The app's bottom navigation: a rounded bar that floats above the content
/// with a gap on every side, instead of a full-width strip that takes over
/// the bottom of the screen.
///
/// Meant for a `Scaffold` with `extendBody: true`, so tab content runs behind
/// it — the Scaffold then reports the bar's height (margins included) in
/// `MediaQuery.padding.bottom`, which scrolling tabs add to their bottom
/// padding so their last items can still be scrolled clear of the bar.
class FloatingNavBar extends StatelessWidget {
  final List<FloatingNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const double _height = 64;
  static const double _radius = 32;

  @override
  Widget build(BuildContext context) {
    // Sit above the system gesture/home indicator, not on it.
    final inset = MediaQuery.of(context).viewPadding.bottom;
    final bottomMargin = math.max(inset - 10, 12.0);

    // A soft fade behind the bar, so content scrolling past its edges and
    // below it recedes instead of competing with the tab labels.
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomMargin),
        child: _bar(),
      ),
    );
  }

  Widget _bar() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        // Content scrolling underneath shows through, softly blurred.
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: _height,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF141414).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(
                color: AppColors.primaryWhite.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < items.length; i++)
                  _NavItem(
                    item: items[i],
                    isSelected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final FloatingNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusWrapper(
      onTap: onTap,
      borderRadius: 26,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.red.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvg(
              asset: item.icon,
              width: 22,
              height: 22,
              color: isSelected
                  ? AppColors.primaryWhite
                  : AppColors.primaryGray,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? AppColors.primaryWhite
                    : AppColors.primaryGray,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
