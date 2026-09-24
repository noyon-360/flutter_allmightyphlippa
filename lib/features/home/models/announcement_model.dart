enum AnnouncementType { update, feature, maintenance, important, info }

/// A message from LABBY shown at the top of Home (new version, feature,
/// maintenance notice, ...). Managed by admins through the backend.
class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final AnnouncementType type;

  /// Optional button, e.g. "Update now" opening the store page.
  final String? actionLabel;
  final String? actionUrl;

  final DateTime? updatedAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.actionLabel,
    this.actionUrl,
    this.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    final typeName = json['type']?.toString();
    return AnnouncementModel(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: AnnouncementType.values.firstWhere(
        (t) => t.name == typeName,
        orElse: () => AnnouncementType.info,
      ),
      actionLabel: _nonEmpty(json['actionLabel']),
      actionUrl: _nonEmpty(json['actionUrl']),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  static String? _nonEmpty(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  bool get hasAction => actionUrl != null && actionLabel != null;

  /// What "dismissed" is remembered against. Includes the edit time, so an
  /// announcement an admin changes after a user closed it shows up again.
  String get dismissKey => '$id@${updatedAt?.millisecondsSinceEpoch ?? 0}';
}
