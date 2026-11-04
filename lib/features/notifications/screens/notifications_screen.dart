import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/tv_device.dart';
import '../models/app_notification_model.dart';
import '../services/notification_inbox_service.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inbox = NotificationInboxService.to;
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, color: context.palette.textPrimary),
          onPressed: Get.back,
        ),
        title: Text(
          'Notifications',
          style: TextStyle(color: context.palette.textPrimary),
        ),
        actions: [
          Obx(() {
            if (inbox.unreadCount == 0) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Mark all as read',
              icon: Icon(Icons.done_all, color: context.palette.textPrimary),
              onPressed: inbox.markAllRead,
            );
          }),
          Obx(() {
            if (inbox.items.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Clear all',
              icon: Icon(
                Icons.delete_sweep_outlined,
                color: context.palette.textPrimary,
              ),
              onPressed: () => _confirmClear(context, inbox),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (inbox.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none, color: context.palette.textPrimary.withValues(alpha: 0.38), size: 64),
                SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(color: context.palette.textPrimary.withValues(alpha: 0.54), fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: inbox.items.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final notification = inbox.items[index];
            return Dismissible(
              key: ValueKey(notification.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => inbox.remove(notification.id),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete_outline, color: AppColors.red),
              ),
              child: _NotificationCard(
                notification: notification,
                onTap: () {
                  inbox.markRead(notification.id);
                  Get.find<NotificationService>().openFromData(
                    notification.data,
                  );
                },
                // A remote can't swipe: give TV a delete button instead.
                onDelete: TvDevice.isTv
                    ? () => inbox.remove(notification.id)
                    : null,
              ),
            );
          },
        );
      }),
    );
  }

  void _confirmClear(BuildContext context, NotificationInboxService inbox) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.palette.surface,
        title: Text(
          'Clear Notifications',
          style: TextStyle(color: context.palette.textPrimary),
        ),
        content: Text(
          'Remove all notifications?',
          style: TextStyle(color: context.palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.palette.textPrimary.withValues(alpha: 0.54)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              inbox.clear();
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotificationModel notification;
  final VoidCallback onTap;

  /// Shown as a delete button when set (TV, where swipe-to-dismiss can't be
  /// done with a remote).
  final VoidCallback? onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);
    // The InkWell's focus highlight is painted under the card's opaque
    // background, so on TV use the focus ring instead.
    if (TvDevice.isTv) {
      return TvFocusWrapper(onTap: onTap, borderRadius: 14, child: card);
    }
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: card,
    );
  }

  Widget _buildCard(BuildContext context) {
    final isRead = notification.isRead;
    return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? context.palette.textPrimary.withValues(alpha: 0.07)
                : AppColors.red.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: isRead ? 0.08 : 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRead ? Icons.notifications_none : Icons.notifications_active,
                color: AppColors.red,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notification.title.isNotEmpty)
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: context.palette.textPrimary,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: context.palette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('MMM d, h:mm a').format(notification.receivedAt),
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline, color: AppColors.red),
                onPressed: onDelete,
              ),
          ],
        ),
    );
  }
}
