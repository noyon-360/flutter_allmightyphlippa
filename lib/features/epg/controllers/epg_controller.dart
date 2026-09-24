import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/auth_storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../models/epg_program_model.dart';
import '../models/epg_reminder_model.dart';
import '../repositories/epg_repository.dart';
import '../screens/epg_reminders_screen.dart';

class EpgController extends GetxController with WidgetsBindingObserver {
  static EpgController get to => Get.find<EpgController>();

  final EpgRepository _repo = EpgRepository();
  final AuthStorageService _storage = Get.find<AuthStorageService>();

  final programs = <EpgProgramModel>[].obs;
  final reminders = <EpgReminderModel>[].obs;
  final isLoadingEpg = false.obs;
  final isLoadingReminders = false.obs;

  // Set of keys for O(1) reminder lookup: "channelId_startMs"
  final _reminderKeys = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    loadReminders();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Alerts are marked notified/expire while the app is in the background, so
  /// refresh the list when the user comes back to it.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) loadReminders();
  }

  bool hasReminder(EpgProgramModel program, String channelId) =>
      _reminderKeys.contains(program.reminderKey(channelId));

  Future<void> fetchEpg(int streamId) async {
    isLoadingEpg.value = true;
    programs.clear();
    try {
      final playlist = await _storage.getPlaylistData();
      final result = await _repo.getChannelEpg(
        serverUrl: playlist.url,
        username: playlist.username,
        password: playlist.password,
        streamId: streamId,
      );
      result.fold(
        (f) => Get.snackbar('Error', f.message,
            backgroundColor: Colors.red, colorText: Colors.white),
        (s) => programs.assignAll(s.data),
      );
    } finally {
      isLoadingEpg.value = false;
    }
  }

  Future<void> loadReminders() async {
    isLoadingReminders.value = true;
    try {
      final result = await _repo.getReminders();
      result.fold(
        (_) {},
        (s) {
          reminders.assignAll(s.data);
          _reminderKeys
            ..clear()
            ..addAll(s.data.map((r) => r.key));
        },
      );
    } finally {
      isLoadingReminders.value = false;
    }
  }

  Future<void> setReminder({
    required String channelId,
    required String channelName,
    required EpgProgramModel program,
  }) async {
    // Alerts are delivered as push notifications, so without permission the
    // alert could never fire. Ask now (in context) rather than only at launch,
    // and don't claim success if the user says no.
    final notifications = Get.find<NotificationService>();
    if (!await notifications.ensurePermission()) {
      _showNotificationsOffDialog();
      return;
    }

    final result = await _repo.createReminder(
      channelId: channelId,
      channelName: channelName,
      programName: program.title,
      programStartTime: program.startTime,
      programEndTime: program.endTime,
    );
    result.fold(
      (f) => Get.snackbar('Error', f.message,
          backgroundColor: Colors.red, colorText: Colors.white),
      (s) {
        reminders.add(s.data);
        _reminderKeys.add(s.data.key);
        programs.refresh();
        Get.snackbar(
          'Reminder Set',
          'You\'ll be notified 5 min before "${program.title}" starts.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          mainButton: TextButton(
            onPressed: () => Get.to(() => const EpgRemindersScreen()),
            child: const Text('View', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  void _showNotificationsOffDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Turn on notifications'),
        content: Text(
          Platform.isIOS
              ? 'LABBY needs notifications to alert you when a program is '
                    'about to start. Enable them in Settings > LABBY > '
                    'Notifications.'
              : 'LABBY needs notifications to alert you when a program is '
                    'about to start. Enable them in your phone\'s Settings > '
                    'Apps > LABBY > Notifications.',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Not now')),
          if (Platform.isIOS)
            TextButton(
              onPressed: () {
                Get.back();
                launchUrl(Uri.parse('app-settings:'));
              },
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
  }

  Future<void> deleteReminder(EpgReminderModel reminder) async {
    final result = await _repo.deleteReminder(reminder.id);
    result.fold(
      (f) => Get.snackbar('Error', f.message,
          backgroundColor: Colors.red, colorText: Colors.white),
      (_) {
        reminders.remove(reminder);
        _reminderKeys.remove(reminder.key);
      },
    );
  }
}
