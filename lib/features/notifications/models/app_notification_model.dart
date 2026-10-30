import 'package:firebase_messaging/firebase_messaging.dart';

/// A push notification kept in the in-app inbox.
class AppNotificationModel {
  final String id;
  final String title;
  final String body;

  /// The FCM `data` map, kept so tapping the inbox entry opens the same place
  /// as tapping the push.
  final Map<String, dynamic> data;
  final DateTime receivedAt;
  final bool isRead;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.receivedAt,
    this.isRead = false,
  });

  /// Returns null for data-only messages: the user never saw those as a
  /// notification, so they don't belong in the inbox.
  static AppNotificationModel? fromRemoteMessage(
    RemoteMessage message, {
    bool isRead = false,
  }) {
    final notification = message.notification;
    if (notification == null) return null;

    final receivedAt = message.sentTime ?? DateTime.now();
    return AppNotificationModel(
      id: message.messageId ?? '${receivedAt.millisecondsSinceEpoch}',
      title: notification.title ?? '',
      body: notification.body ?? '',
      data: message.data,
      receivedAt: receivedAt,
      isRead: isRead,
    );
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: Map<String, dynamic>.from(json['data'] ?? const {}),
      receivedAt: DateTime.parse(json['receivedAt']).toLocal(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'data': data,
    'receivedAt': receivedAt.toUtc().toIso8601String(),
    'isRead': isRead,
  };

  AppNotificationModel copyWith({bool? isRead}) => AppNotificationModel(
    id: id,
    title: title,
    body: body,
    data: data,
    receivedAt: receivedAt,
    isRead: isRead ?? this.isRead,
  );
}
