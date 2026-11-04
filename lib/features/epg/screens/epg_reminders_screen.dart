import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/epg_controller.dart';
import '../models/epg_reminder_model.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

class EpgRemindersScreen extends StatelessWidget {
  const EpgRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = EpgController.to;
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: context.palette.textPrimary),
        title: Text(
          'My EPG Reminders',
          style: TextStyle(color: context.palette.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.palette.textPrimary),
            onPressed: ctrl.loadReminders,
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoadingReminders.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.red),
          );
        }

        if (ctrl.reminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none, color: context.palette.textPrimary.withValues(alpha: 0.38), size: 64),
                SizedBox(height: 16),
                Text(
                  'No upcoming reminders',
                  style: TextStyle(color: context.palette.textPrimary.withValues(alpha: 0.54), fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Open a live channel and tap the bell icon\nto set a program reminder.',
                  style: TextStyle(color: context.palette.textPrimary.withValues(alpha: 0.38), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.reminders.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final reminder = ctrl.reminders[index];
            return _ReminderCard(reminder: reminder, ctrl: ctrl);
          },
        );
      }),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final EpgReminderModel reminder;
  final EpgController ctrl;

  const _ReminderCard({required this.reminder, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d').format(reminder.programStartTime);
    final timeStr = DateFormat('h:mm a').format(reminder.programStartTime);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.textPrimary.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active,
              color: AppColors.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.programName,
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  reminder.channelName,
                  style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr at $timeStr  •  ${reminder.notifyMinutesBefore} min before',
                  style: TextStyle(color: context.palette.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: context.palette.textPrimary.withValues(alpha: 0.38)),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.palette.surface,
        title: Text('Delete Reminder', style: TextStyle(color: context.palette.textPrimary)),
        content: Text(
          'Remove reminder for "${reminder.programName}"?',
          style: TextStyle(color: context.palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.palette.textPrimary.withValues(alpha: 0.54))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.deleteReminder(reminder);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}
