import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../screens/notifications_screen.dart';
import '../services/notification_inbox_service.dart';

/// Opens the notifications screen, with a badge for the unread count.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => Get.to(
        () => const NotificationsScreen(),
        transition: Transition.rightToLeft,
      ),
      icon: Obx(() {
        final unread = NotificationInboxService.to.unreadCount;
        return Badge(
          isLabelVisible: unread > 0,
          backgroundColor: AppColors.red,
          label: Text(unread > 99 ? '99+' : '$unread'),
          child: const Icon(
            Icons.notifications_none_outlined,
            color: AppColors.primaryWhite,
            size: 28,
          ),
        );
      }),
    );
  }
}
