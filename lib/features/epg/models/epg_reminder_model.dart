class EpgReminderModel {
  final String id;
  final String channelId;
  final String channelName;
  final String programName;
  final DateTime programStartTime;
  final DateTime? programEndTime;
  final int notifyMinutesBefore;
  final bool isNotified;

  EpgReminderModel({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.programName,
    required this.programStartTime,
    this.programEndTime,
    required this.notifyMinutesBefore,
    required this.isNotified,
  });

  factory EpgReminderModel.fromJson(Map<String, dynamic> json) {
    return EpgReminderModel(
      id: json['_id'] ?? '',
      channelId: json['channelId'] ?? '',
      channelName: json['channelName'] ?? '',
      programName: json['programName'] ?? '',
      programStartTime: DateTime.parse(json['programStartTime']),
      programEndTime: json['programEndTime'] != null
          ? DateTime.tryParse(json['programEndTime'])
          : null,
      notifyMinutesBefore: json['notifyMinutesBefore'] ?? 5,
      isNotified: json['isNotified'] ?? false,
    );
  }

  // Matches EpgProgramModel.reminderKey
  String get key => '${channelId}_${programStartTime.millisecondsSinceEpoch}';
}
