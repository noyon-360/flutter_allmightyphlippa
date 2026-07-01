import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_storage_service.dart';
import '../models/epg_program_model.dart';
import '../models/epg_reminder_model.dart';
import '../repositories/epg_repository.dart';

class EpgController extends GetxController {
  static EpgController get to => Get.find<EpgController>();

  final EpgRepository _repo = EpgRepository();
  final AuthStorageService _storage = Get.find<AuthStorageService>();

  final programs = <EpgProgramModel>[].obs;
  final reminders = <EpgReminderModel>[].obs;
  final isLoadingEpg = false.obs;
  final isLoadingReminders = false.obs;

  // Set of keys for O(1) reminder lookup: "channelId_startMs"
  final _reminderKeys = <String>{};

  @override
  void onInit() {
    super.onInit();
    loadReminders();
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
        );
      },
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
