import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_service_web.dart'
    if (dart.library.io) 'notification_service_stub.dart' as web_notif;

/// Platform-adaptive notification service.
///
/// - Android / iOS: flutter_local_notifications with exact scheduling.
/// - Web: browser Notification API via dart:html.
///   Note: browser notifications only fire while the tab is open.
///   For background delivery, wire up the service worker (web/sw.js).
class NotificationService {
  static const _channelId = 'wordprogressor_deadlines';
  static const _channelName = 'Deadline-Erinnerungen';
  static const _channelDesc =
      'Benachrichtigungen für bevorstehende Projekt-Deadlines';

  static Future<void> initialize(
      FlutterLocalNotificationsPlugin plugin) async {
    if (kIsWeb) {
      await web_notif.requestWebPermission();
      return;
    }
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  static Future<void> requestPermissions(
      FlutterLocalNotificationsPlugin plugin) async {
    if (kIsWeb) {
      await web_notif.requestWebPermission();
      return;
    }
    final ios = plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  static Future<void> scheduleDeadlineReminder({
    required FlutterLocalNotificationsPlugin plugin,
    required int id,
    required String projectTitle,
    required DateTime deadline,
  }) async {
    final reminderDate = deadline.subtract(const Duration(days: 3));
    if (reminderDate.isBefore(DateTime.now())) return;

    if (kIsWeb) {
      final delay = reminderDate.difference(DateTime.now());
      Future.delayed(delay, () {
        web_notif.showWebNotification(
          title: '⏱ Deadline in 3 Tagen',
          body: '"$projectTitle" ist in 3 Tagen fällig.',
        );
      });
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await plugin.zonedSchedule(
      id,
      '⏱ Deadline in 3 Tagen',
      '"$projectTitle" ist in 3 Tagen fällig.',
      tz.TZDateTime.from(reminderDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelForProject(
      FlutterLocalNotificationsPlugin plugin, int id) async {
    if (kIsWeb) return;
    await plugin.cancel(id);
  }

  static Future<void> cancelAll(
      FlutterLocalNotificationsPlugin plugin) async {
    if (kIsWeb) return;
    await plugin.cancelAll();
  }
}