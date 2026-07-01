import 'dart:convert';

class EpgProgramModel {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isNowPlaying;

  EpgProgramModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.isNowPlaying,
  });

  factory EpgProgramModel.fromJson(Map<String, dynamic> json) {
    String title = json['title'] ?? '';
    String description = json['description'] ?? '';

    // Xtream Codes EPG encodes title/description as base64
    try {
      title = utf8.decode(base64.decode(title));
    } catch (_) {}
    try {
      description = utf8.decode(base64.decode(description));
    } catch (_) {}

    DateTime start;
    DateTime end;

    if (json['start_timestamp'] != null) {
      start = DateTime.fromMillisecondsSinceEpoch(
          int.parse(json['start_timestamp'].toString()) * 1000);
    } else {
      start = DateTime.tryParse(json['start'] ?? '') ?? DateTime.now();
    }

    if (json['stop_timestamp'] != null) {
      end = DateTime.fromMillisecondsSinceEpoch(
          int.parse(json['stop_timestamp'].toString()) * 1000);
    } else {
      end = DateTime.tryParse(json['end'] ?? '') ?? DateTime.now();
    }

    return EpgProgramModel(
      id: json['id']?.toString() ?? '',
      title: title.trim().isNotEmpty ? title : 'Unknown Program',
      description: description,
      startTime: start,
      endTime: end,
      isNowPlaying: json['now_playing'] == 1 || json['now_playing'] == true,
    );
  }

  bool get isFuture => startTime.isAfter(DateTime.now());

  String get timeRange {
    String fmt(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${fmt(startTime)} – ${fmt(endTime)}';
  }

  // Unique key used to check if a reminder exists for this program + channel
  String reminderKey(String channelId) =>
      '${channelId}_${startTime.millisecondsSinceEpoch}';
}
