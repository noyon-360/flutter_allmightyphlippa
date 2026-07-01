import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/epg_controller.dart';
import '../models/epg_reminder_model.dart';

class EpgRemindersScreen extends StatelessWidget {
  const EpgRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = EpgController.to;
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'My EPG Reminders',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
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
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none, color: Colors.white38, size: 64),
                SizedBox(height: 16),
                Text(
                  'No upcoming reminders',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Open a live channel and tap the bell icon\nto set a program reminder.',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
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
    final timeStr = DateFormat('HH:mm').format(reminder.programStartTime);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.containerBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  reminder.channelName,
                  style: const TextStyle(color: AppColors.primaryGray, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr at $timeStr  •  ${reminder.notifyMinutesBefore} min before',
                  style: const TextStyle(color: AppColors.primaryGray, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white38),
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
        backgroundColor: AppColors.containerBgColor,
        title: const Text('Delete Reminder', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove reminder for "${reminder.programName}"?',
          style: const TextStyle(color: AppColors.primaryGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
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
