import '../../../core/api/api_client.dart';
import '../../../core/api/network_result.dart';
import '../../../core/constants/api_constants.dart';
import '../models/epg_program_model.dart';
import '../models/epg_reminder_model.dart';

class EpgRepository {
  final ApiClient _apiClient = ApiClient();

  NetworkResult<List<EpgProgramModel>> getChannelEpg({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
    int limit = 10,
  }) async {
    return await _apiClient.post(
      endpoint: ApiConstants.epg.schedule,
      data: {
        'serverUrl': serverUrl,
        'username': username,
        'password': password,
        'streamId': streamId,
        'limit': limit,
      },
      fromJsonT: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(EpgProgramModel.fromJson)
              .toList();
        }
        return <EpgProgramModel>[];
      },
    );
  }

  /// Fetches every program overlapping [from]..[to] for one channel — used
  /// by the EPG timeline to show a whole day (past + current + future)
  /// rather than just current+upcoming. Requires a backend that understands
  /// the `from`/`to` fields on `/epg/schedule`; falls back to an empty list
  /// on old backends the same way any other unrecognized-field 200 would.
  NetworkResult<List<EpgProgramModel>> getChannelSchedule({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
    required DateTime from,
    required DateTime to,
  }) async {
    return await _apiClient.post(
      endpoint: ApiConstants.epg.schedule,
      data: {
        'serverUrl': serverUrl,
        'username': username,
        'password': password,
        'streamId': streamId,
        'from': from.toUtc().millisecondsSinceEpoch ~/ 1000,
        'to': to.toUtc().millisecondsSinceEpoch ~/ 1000,
      },
      fromJsonT: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(EpgProgramModel.fromJson)
              .toList();
        }
        return <EpgProgramModel>[];
      },
    );
  }

  NetworkResult<EpgReminderModel> createReminder({
    required String channelId,
    required String channelName,
    required String programName,
    required DateTime programStartTime,
    DateTime? programEndTime,
    int notifyMinutesBefore = 5,
  }) async {
    return await _apiClient.post(
      endpoint: ApiConstants.epg.createReminder,
      data: {
        'channelId': channelId,
        'channelName': channelName,
        'programName': programName,
        'programStartTime': programStartTime.toUtc().toIso8601String(),
        if (programEndTime != null)
          'programEndTime': programEndTime.toUtc().toIso8601String(),
        'notifyMinutesBefore': notifyMinutesBefore,
      },
      fromJsonT: (json) => EpgReminderModel.fromJson(json),
    );
  }

  NetworkResult<List<EpgReminderModel>> getReminders() async {
    return await _apiClient.get(
      endpoint: ApiConstants.epg.reminders,
      fromJsonT: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(EpgReminderModel.fromJson)
              .toList();
        }
        return <EpgReminderModel>[];
      },
    );
  }

  NetworkResult<void> deleteReminder(String id) async {
    return await _apiClient.delete(
      endpoint: ApiConstants.epg.deleteReminder(id),
      fromJsonT: (_) {},
    );
  }
}
