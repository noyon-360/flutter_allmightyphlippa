import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../../features/epg/controllers/epg_controller.dart';
import '../../features/video/screens/live_video_play_screen.dart';
import 'auth_storage_service.dart';

const _channelId = 'labby_tv_high_importance';
const _channelName = 'LABBY TV Notifications';

/// FCM `data.type` the backend sends for a program alert, and the prefix used
/// to carry it (plus the channel) through a local notification's payload.
const _epgReminderType = 'epg_reminder';
const _epgReminderPayloadPrefix = '$_epgReminderType:';

class NotificationService extends GetxService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiClient _apiClient = ApiClient();

  late final AuthStorageService _authStorage;

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
      _showLocalNotification(message);
    });
  }

  void _listenBackgroundTap() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      DPrint.log('[FCM] background tap: ${message.data}');
      _navigateFromMessage(message);
    });
  }

  Future<void> _handleTerminatedTap() async {
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      DPrint.log('[FCM] terminated tap: ${initial.data}');
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateFromMessage(initial);
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

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: _payloadFor(message.data),
    );
  }

  /// A local notification carries a single string payload, so program alerts
  /// are encoded as `epg_reminder:<channelId>` and anything else as its route.
  String? _payloadFor(Map<String, dynamic> data) {
    if (data['type'] == _epgReminderType && data['channelId'] != null) {
      return '$_epgReminderPayloadPrefix${data['channelId']}';
    }
    return data['route'] as String?;
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    if (payload.startsWith(_epgReminderPayloadPrefix)) {
      _openReminderChannel(payload.substring(_epgReminderPayloadPrefix.length));
    } else {
      Get.toNamed(payload);
    }
  }

  void _navigateFromMessage(RemoteMessage message) {
    if (message.data['type'] == _epgReminderType) {
      _openReminderChannel(message.data['channelId'] as String?);
      return;
    }
    final route = message.data['route'] as String?;
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
      // Invalidate the token on Firebase's side so it can't be reused
      await _fcm.deleteToken();
    }
  }
}
