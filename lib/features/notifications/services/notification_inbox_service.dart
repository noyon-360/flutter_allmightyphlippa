import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_notification_model.dart';

/// The on-device history of push notifications, shown on the notifications
/// screen. The backend doesn't expose a notification list, so this is built
/// from the messages the device receives.
class NotificationInboxService extends GetxService with WidgetsBindingObserver {
  static NotificationInboxService get to =>
      Get.find<NotificationInboxService>();

  static const _boxName = 'notification_inbox';
  static const _itemsKey = 'items';
  static const _pendingFileName = 'notification_inbox_pending.jsonl';
  static const _maxItems = 100;
  static const _trayChannel = MethodChannel('labby/notification_tray');

  @visibleForTesting
  static Future<Directory> Function() pendingDirectory =
      getApplicationSupportDirectory;

  final items = <AppNotificationModel>[].obs;

  Box? _box;

  int get unreadCount => items.where((n) => !n.isRead).length;

  Future<NotificationInboxService> init() async {
    WidgetsBinding.instance.addObserver(this);
    try {
      _box = await Hive.openBox(_boxName);
      _load();
    } catch (e) {
      DPrint.error('[Inbox] open error: $e');
    }
    ever(items, (_) => _syncBadge());
    await _refresh();
    return this;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Messages received while backgrounded are waiting to be collected.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  /// Collects what arrived while we weren't looking, then corrects the icon
  /// badge: pushes set it from the backend's count, which the app can't see.
  Future<void> _refresh() async {
    await _drainPending();
    await _collectFromTray();
    await _syncBadge();
  }

  /// Records [message] for the FCM background handler. That handler runs in
  /// its own isolate and Hive can't be shared across isolates, so it appends
  /// to a file which the main isolate moves into the box.
  static Future<void> savePending(RemoteMessage message) async {
    final notification = AppNotificationModel.fromRemoteMessage(message);
    if (notification == null) return;
    try {
      final file = await _pendingFile();
      await file.writeAsString(
        '${jsonEncode(notification.toJson())}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      DPrint.error('[Inbox] savePending error: $e');
    }
  }

  static Future<File> _pendingFile() async {
    final dir = await pendingDirectory();
    return File('${dir.path}/$_pendingFileName');
  }

  /// A message can reach us twice (the background handler, then the tap that
  /// opens the app), so the first copy wins; [isRead] only ever marks it read.
  Future<void> add(RemoteMessage message, {bool isRead = false}) async {
    final notification = AppNotificationModel.fromRemoteMessage(
      message,
      isRead: isRead,
    );
    if (notification == null) return;

    if (items.any((n) => n.id == notification.id)) {
      if (isRead) await markRead(notification.id);
      return;
    }
    _merge([notification]);
    await _save();
  }

  Future<void> markRead(String id) async {
    final index = items.indexWhere((n) => n.id == id);
    if (index == -1 || items[index].isRead) return;
    items[index] = items[index].copyWith(isRead: true);
    await _save();
  }

  Future<void> markAllRead() async {
    items.assignAll(items.map((n) => n.copyWith(isRead: true)));
    await _save();
  }

  Future<void> remove(String id) async {
    items.removeWhere((n) => n.id == id);
    await _save();
  }

  /// Empties the inbox, including anything still pending. Called on logout so
  /// the next account on this device can't read this user's notifications.
  Future<void> clear() async {
    items.clear();
    await _save();
    // Otherwise whatever is still in the tray would come back on next resume.
    await _takeFromTray();
    try {
      final file = await _pendingFile();
      if (await file.exists()) await file.delete();
    } catch (e) {
      DPrint.error('[Inbox] clear error: $e');
    }
  }

  void _load() {
    final stored = _box?.get(_itemsKey) as String?;
    if (stored == null) return;
    items.assignAll(
      (jsonDecode(stored) as List).whereType<Map<String, dynamic>>().map(
        AppNotificationModel.fromJson,
      ),
    );
  }

  Future<void> _save() async {
    try {
      await _box?.put(_itemsKey, jsonEncode(items));
    } catch (e) {
      DPrint.error('[Inbox] save error: $e');
    }
  }

  /// Moves the pending file aside before reading so a message arriving from
  /// the background isolate mid-read lands in a fresh file instead of being
  /// deleted unread.
  Future<void> _drainPending() async {
    try {
      final file = await _pendingFile();
      if (!await file.exists()) return;

      final draining = await file.rename('${file.path}.draining');
      final lines = await draining.readAsLines();
      await draining.delete();

      final pending = <AppNotificationModel>[];
      for (final line in lines) {
        try {
          pending.add(AppNotificationModel.fromJson(jsonDecode(line)));
        } catch (e) {
          DPrint.error('[Inbox] skipped bad pending line: $e');
        }
      }
      _merge(pending);
      await _save();
    } catch (e) {
      DPrint.error('[Inbox] drain error: $e');
    }
  }

  /// iOS only runs the background handler for silent-capable pushes, so the
  /// rest are picked up from Notification Center. Android doesn't need this:
  /// its handler runs for every notification.
  Future<void> _collectFromTray() async {
    final delivered = await _takeFromTray();
    if (delivered.isEmpty) return;
    try {
      _merge(
        delivered
            .map((e) => AppNotificationModel.fromJson(Map.from(e)))
            .toList(),
      );
      await _save();
    } catch (e) {
      DPrint.error('[Inbox] tray parse error: $e');
    }
  }

  Future<List<Map>> _takeFromTray() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return const [];
    try {
      return await _trayChannel.invokeListMethod<Map>('takeDelivered') ??
          const [];
    } catch (e) {
      DPrint.error('[Inbox] tray read error: $e');
      return const [];
    }
  }

  Future<void> _syncBadge() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await _trayChannel.invokeMethod('setBadge', unreadCount);
    } catch (e) {
      DPrint.error('[Inbox] badge error: $e');
    }
  }

  /// Adds the [incoming] ones not already held, newest first, keeping the
  /// inbox to [_maxItems].
  void _merge(List<AppNotificationModel> incoming) {
    final known = items.map((n) => n.id).toSet();
    final merged = [...items, ...incoming.where((n) => known.add(n.id))]
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    items.assignAll(merged.take(_maxItems));
  }
}
