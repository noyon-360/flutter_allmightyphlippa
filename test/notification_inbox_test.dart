import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_almightyflippa/features/notifications/models/app_notification_model.dart';
import 'package:flutter_almightyflippa/features/notifications/services/notification_inbox_service.dart';
import 'package:flutter_almightyflippa/features/notifications/screens/notifications_screen.dart';
import 'package:flutter_almightyflippa/features/notifications/widgets/notification_bell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  RemoteMessage message(
    String id, {
    DateTime? sentTime,
    bool hasNotification = true,
  }) => RemoteMessage(
    messageId: id,
    sentTime: sentTime ?? DateTime(2026, 10, 30, 12),
    data: const {'type': 'epg_reminder', 'channelId': '42'},
    notification: hasNotification
        ? RemoteNotification(title: 'Title $id', body: 'Body $id')
        : null,
  );

  Future<NotificationInboxService> openInbox() =>
      NotificationInboxService().init();

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('inbox_test');
    Hive.init(dir.path);
    NotificationInboxService.pendingDirectory = () async => dir;
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('model survives the JSON round trip', () {
    final original = AppNotificationModel.fromRemoteMessage(message('1'))!;
    final restored = AppNotificationModel.fromJson(original.toJson());

    expect(restored.id, '1');
    expect(restored.title, 'Title 1');
    expect(restored.body, 'Body 1');
    expect(restored.data['channelId'], '42');
    expect(restored.receivedAt, original.receivedAt);
    expect(restored.isRead, isFalse);
  });

  test('data-only messages stay out of the inbox', () async {
    final inbox = await openInbox();
    await inbox.add(message('1', hasNotification: false));
    await NotificationInboxService.savePending(
      message('2', hasNotification: false),
    );

    expect(inbox.items, isEmpty);
    expect(
      File('${dir.path}/notification_inbox_pending.jsonl').existsSync(),
      isFalse,
    );
  });

  test('keeps newest first, counts unread, and persists', () async {
    final inbox = await openInbox();
    await inbox.add(message('old', sentTime: DateTime(2026, 10, 1)));
    await inbox.add(message('new', sentTime: DateTime(2026, 10, 2)));
    await inbox.markRead('old');

    expect(inbox.items.map((n) => n.id), ['new', 'old']);
    expect(inbox.unreadCount, 1);

    await Hive.close();
    final reopened = await openInbox();
    expect(reopened.items.map((n) => n.id), ['new', 'old']);
    expect(reopened.unreadCount, 1);
  });

  test('moves background messages into the inbox', () async {
    final inbox = await openInbox();
    await NotificationInboxService.savePending(message('1'));
    await NotificationInboxService.savePending(message('2'));

    inbox.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(inbox.items.map((n) => n.id), containsAll(['1', '2']));
    expect(inbox.unreadCount, 2);
  });

  test(
    'a tap on a message the handler already saved is not a duplicate',
    () async {
      final inbox = await openInbox();
      await NotificationInboxService.savePending(message('1'));

      // The tap arrives before the pending file is drained.
      await inbox.add(message('1'), isRead: true);
      inbox.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(inbox.items, hasLength(1));
      expect(inbox.items.single.isRead, isTrue);
    },
  );

  test('keeps only the latest 100', () async {
    final inbox = await openInbox();
    final start = DateTime(2026);
    for (var i = 0; i < 105; i++) {
      await inbox.add(message('$i', sentTime: start.add(Duration(minutes: i))));
    }

    expect(inbox.items, hasLength(100));
    expect(inbox.items.first.id, '104');
    expect(inbox.items.last.id, '5');
  });

  test('clear removes stored and pending notifications', () async {
    final inbox = await openInbox();
    await inbox.add(message('1'));
    await NotificationInboxService.savePending(message('2'));

    await inbox.clear();
    await Hive.close();

    final reopened = await openInbox();
    expect(reopened.items, isEmpty);
  });

  group('iOS tray', () {
    const channel = MethodChannel('labby/notification_tray');
    late List<Map<String, Object?>> tray;
    late List<int> badges;

    Map<String, Object?> delivered(String id) => {
      'id': id,
      'title': 'Title $id',
      'body': 'Body $id',
      'data': <Object?, Object?>{'type': 'epg_reminder', 'channelId': '42'},
      'receivedAt': '2026-10-30T09:48:00Z',
    };

    setUp(() {
      tray = [];
      badges = [];
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'setBadge') {
              badges.add(call.arguments as int);
              return null;
            }
            final taken = [...tray];
            tray.clear();
            return taken;
          });
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('collects tray pushes the app never saw, as unread', () async {
      tray.add(delivered('1'));

      final inbox = await openInbox();

      expect(inbox.items.single.title, 'Title 1');
      expect(inbox.items.single.data['channelId'], '42');
      expect(inbox.items.single.isRead, isFalse);
      expect(inbox.items.single.receivedAt.isUtc, isFalse);
      expect(badges.last, 1);
    });

    test('a stale badge with nothing behind it is reset to 0', () async {
      await openInbox();
      expect(badges.last, 0);
    });

    test('does not duplicate a push the handler also saved', () async {
      await NotificationInboxService.savePending(message('1'));
      tray.add(delivered('1'));

      final inbox = await openInbox();

      expect(inbox.items, hasLength(1));
    });

    test('badge follows the unread count', () async {
      tray.addAll([delivered('1'), delivered('2')]);
      final inbox = await openInbox();
      expect(badges.last, 2);

      await inbox.markRead('1');
      await Future<void>.delayed(Duration.zero);
      expect(badges.last, 1);

      await inbox.markAllRead();
      await Future<void>.delayed(Duration.zero);
      expect(badges.last, 0);
    });

    test('clear empties the tray so nothing comes back', () async {
      final inbox = await openInbox();
      tray.add(delivered('1'));

      await inbox.clear();
      inbox.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(tray, isEmpty);
      expect(inbox.items, isEmpty);
    });
  });

  group('UI', () {
    // Never opens its box: Hive's writes can't finish in testWidgets' fake
    // async zone, and these tests only care about what's on screen.
    NotificationInboxService putInbox() {
      addTearDown(Get.reset);
      return Get.put(NotificationInboxService());
    }

    testWidgets('bell shows the unread count', (tester) async {
      final inbox = putInbox();
      await inbox.add(message('1'));
      await inbox.add(message('2'));

      await tester.pumpWidget(
        const GetMaterialApp(home: Scaffold(body: NotificationBell())),
      );
      expect(find.text('2'), findsOneWidget);

      await inbox.markAllRead();
      await tester.pump();
      expect(find.text('2'), findsNothing);
    });

    testWidgets('screen lists notifications and removes on swipe', (
      tester,
    ) async {
      final inbox = putInbox();
      await inbox.add(message('1'));

      await tester.pumpWidget(
        const GetMaterialApp(home: NotificationsScreen()),
      );
      expect(find.text('Title 1'), findsOneWidget);
      expect(find.text('Body 1'), findsOneWidget);

      await tester.drag(find.text('Title 1'), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(inbox.items, isEmpty);
      await tester.pump();
      expect(find.text('No notifications yet'), findsOneWidget);
    });
  });
}
