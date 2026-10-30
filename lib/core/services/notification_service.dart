import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../../features/epg/controllers/epg_controller.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/history/utils/open_watch_history_item.dart';
import '../../features/notifications/services/notification_inbox_service.dart';
import '../../features/video/screens/live_video_play_screen.dart';
import 'auth_storage_service.dart';
import 'watch_history_service.dart';

const _channelId = 'labby_tv_high_importance';
const _channelName = 'LABBY TV Notifications';

/// FCM `data.type` values the backend sends that open a specific screen.
const _epgReminderType = 'epg_reminder';
const _continueWatchingType = 'continue_watching';

class NotificationService extends GetxService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiClient _apiClient = ApiClient();

  late final AuthStorageService _authStorage;

  NotificationInboxService get _inbox => NotificationInboxService.to;

  /// Local notification id -> FCM message id, so tapping a foreground
  /// notification can mark its inbox entry read.
  final Map<int, String> _shownLocally = {};

  @override
  Future<void> onInit() async {
    super.onInit();
    _authStorage = Get.find<AuthStorageService>();
    await _initialize();
  }

  Future<void> _initialize() async {
    await _requestPermission();
    await _setupLocalNotifications();
    await _registerToken();
    _listenForeground();
    _listenBackgroundTap();
    await _handleTerminatedTap();
    _fcm.onTokenRefresh.listen(_syncTokenWithBackend);
  }

  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    DPrint.log('[FCM] permission: ${settings.authorizationStatus}');
  }

  /// Whether the app can post notifications right now, asking the user if it
  /// still can. Call this when a feature actually needs notifications (e.g.
  /// setting a program alert) so the prompt appears in context.
  ///
  /// iOS only ever prompts once (afterwards [AuthorizationStatus.denied] is
  /// final, so the user has to use Settings). Android 13+ can prompt again
  /// until the user picks "Don't allow" twice, so it's asked whenever it
  /// isn't already granted. Returns true if notifications are allowed.
  Future<bool> ensurePermission() async {
    var settings = await _fcm.getNotificationSettings();
    final canAsk =
        settings.authorizationStatus == AuthorizationStatus.notDetermined ||
        (Platform.isAndroid &&
            settings.authorizationStatus == AuthorizationStatus.denied);

    if (!_isGranted(settings) && canAsk) {
      settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final granted = _isGranted(settings);
    DPrint.log('[FCM] ensurePermission: ${settings.authorizationStatus}');
    // A token can't be issued/registered usefully until permission exists.
    if (granted) await _registerToken();
    return granted;
  }

  bool _isGranted(NotificationSettings settings) =>
      settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              importance: Importance.high,
              playSound: true,
            ),
          );
    }
  }

  Future<void> _registerToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        DPrint.log('[FCM] token: $token');
        await _syncTokenWithBackend(token);
      }
    } catch (e) {
      debugPrint('[FCM] getToken error: $e');
    }
  }

  Future<void> _syncTokenWithBackend(String token) async {
    try {
      final isLoggedIn = await _authStorage.isAuthenticated();
      if (!isLoggedIn) return;

      final deviceId = await _authStorage.getOrCreateDeviceId();

      await _apiClient.post<void>(
        endpoint: ApiConstants.user.registerFcmToken,
        data: {
          'fcmToken': token,
          'deviceId': deviceId,
          'platform': Platform.operatingSystem, // "android" | "ios"
        },
        fromJsonT: (_) {},
      );
      DPrint.log('[FCM] token synced — device: $deviceId');
    } catch (e) {
      debugPrint('[FCM] syncToken error: $e');
    }
  }

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((message) {
      DPrint.log('[FCM] foreground: ${message.notification?.title}');
      _inbox.add(message);
      _showLocalNotification(message);
    });
  }

  void _listenBackgroundTap() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      DPrint.log('[FCM] background tap: ${message.data}');
      _inbox.add(message, isRead: true);
      openFromData(message.data);
    });
  }

  Future<void> _handleTerminatedTap() async {
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      DPrint.log('[FCM] terminated tap: ${initial.data}');
      await _inbox.add(initial, isRead: true);
      await Future.delayed(const Duration(milliseconds: 500));
      openFromData(initial.data);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final messageId = message.messageId;
    if (messageId != null) _shownLocally[notification.hashCode] = messageId;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: _payloadFor(message.data),
    );
  }

  /// A local notification carries a single string payload, so the FCM `data`
  /// map travels through it as JSON.
  String? _payloadFor(Map<String, dynamic> data) =>
      data.isEmpty ? null : jsonEncode(data);

  void _onLocalNotificationTap(NotificationResponse response) {
    final messageId = _shownLocally.remove(response.id);
    if (messageId != null) _inbox.markRead(messageId);

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    openFromData(jsonDecode(payload) as Map<String, dynamic>);
  }

  /// Opens what a notification points to, from its FCM `data` map.
  void openFromData(Map<String, dynamic> data) {
    if (data['type'] == _epgReminderType) {
      _openReminderChannel(data['channelId'] as String?);
      return;
    }
    if (data['type'] == _continueWatchingType) {
      _openContinueWatching(data['videoId'] as String?);
      return;
    }
    final route = data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      Get.toNamed(route);
    }
  }

  /// Opens the live player for a program alert's channel. The alert stores the
  /// channel's stream id as its `channelId`; the name comes from the user's
  /// loaded alerts when available (the push itself doesn't carry it).
  Future<void> _openReminderChannel(String? channelId) async {
    final streamId = int.tryParse(channelId ?? '');
    if (streamId == null) return;
    if (!await _authStorage.isAuthenticated()) return;

    var channelName = 'Live TV';
    if (Get.isRegistered<EpgController>()) {
      final match = EpgController.to.reminders
          .firstWhereOrNull((r) => r.channelId == channelId);
      if (match != null) channelName = match.channelName;
    }

    Get.to(
      () => LiveVideoPlayScreen(streamId: streamId, channelName: channelName),
      // Unnamed route: GetX derives its name from the widget type, so opening
      // this while another live player is showing would be silently ignored.
      preventDuplicates: false,
    );
  }

  /// Resumes the video from a continue watching push. Its `videoId` is the
  /// watch history record's id, not a stream id, so the entry has to be looked
  /// up. If it's gone (deleted, or too old to fetch) the history list is the
  /// closest place to send the user.
  Future<void> _openContinueWatching(String? recordId) async {
    if (recordId == null || recordId.isEmpty) return;
    if (!await _authStorage.isAuthenticated()) return;

    final item = await Get.find<WatchHistoryService>().findByRecordId(recordId);
    if (item == null) {
      Get.to(() => const HistoryScreen());
      return;
    }
    openWatchHistoryItem(item);
  }

  /// Call after login so the token for this device is registered.
  Future<void> onUserLogin() => _registerToken();

  /// Call before clearing auth data on logout.
  /// Removes this device's token from the backend and invalidates it locally.
  Future<void> onUserLogout() async {
    try {
      final deviceId = await _authStorage.getOrCreateDeviceId();
      await _apiClient.delete<void>(
        endpoint: ApiConstants.user.removeFcmToken,
        data: {'deviceId': deviceId},
        fromJsonT: (_) {},
      );
      DPrint.log('[FCM] token removed for device: $deviceId');
    } catch (e) {
      debugPrint('[FCM] removeToken error: $e');
    } finally {
      await _inbox.clear();
      // Invalidate the token on Firebase's side so it can't be reused
      await _fcm.deleteToken();
    }
  }
}
