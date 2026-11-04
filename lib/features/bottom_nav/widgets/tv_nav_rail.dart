import 'package:flutter/material.dart';

import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/assest_const.dart';
import '../../../core/utils/app_svg.dart';
import 'floating_nav_bar.dart';

/// Android TV's main navigation: a vertical rail down the left edge, the
/// layout TV apps are expected to use (the phone's [FloatingNavBar] at the
/// bottom reads as a stretched phone UI on a television).
///
/// Left from the page content reaches the rail; Right goes back into it.
class TvNavRail extends StatelessWidget {
  final List<FloatingNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const TvNavRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const double width = 184;

  @override
  Widget build(BuildContext context) {
    // The rail's background runs to the screen edges; its content stays
    // inside the overscan-safe area (TvLayout's padding).
    final safe = MediaQuery.of(context).padding;
    return Container(
      width: width + safe.left,
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        border: Border(
          right: BorderSide(
            color: AppColors.primaryWhite.withValues(alpha: 0.08),
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        12 + safe.left,
        8 + safe.top,
        12,
        8 + safe.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    AssetsConstants.images.logo,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text(
                    'LABBY TV',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primaryWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _RailItem(
                item: items[i],
                isSelected: i == selectedIndex,
                // Opening the app (or coming back) starts on the current tab.
                autofocus: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final FloatingNavItem item;
  final bool isSelected;
  final bool autofocus;
  final VoidCallback onTap;

  const _RailItem({
    required this.item,
    required this.isSelected,
    required this.autofocus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primaryWhite : AppColors.primaryGray;
    return TvFocusWrapper(
      onTap: onTap,
      autofocus: autofocus,
      borderRadius: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.red.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AppSvg(asset: item.icon, width: 22, height: 22, color: color),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
