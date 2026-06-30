import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import 'auth_storage_service.dart';

const _channelId = 'labby_tv_high_importance';
const _channelName = 'LABBY TV Notifications';

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
      payload: message.data['route'] as String?,
    );
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final route = response.payload;
    if (route != null && route.isNotEmpty) {
      Get.toNamed(route);
    }
  }

  void _navigateFromMessage(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      Get.toNamed(route);
    }
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
