import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const _channelId = 'wordprogressor_deadlines';
  static const _channelName = 'Deadline-Erinnerungen';
  static const _channelDesc =
      'Benachrichtigungen für bevorstehende Projekt-Deadlines';

  static Future<void> initialize(
      FlutterLocalNotificationsPlugin plugin) async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await plugin.initialize(settings);
  }

  static Future<void> requestPermissions(
      FlutterLocalNotificationsPlugin plugin) async {
    final ios = plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  /// Schedule a deadline reminder 3 days before the deadline.
  static Future<void> scheduleDeadlineReminder({
    required FlutterLocalNotificationsPlugin plugin,
    required int id,
    required String projectTitle,
    required DateTime deadline,
  }) async {
    final reminderDate = deadline.subtract(const Duration(days: 3));
    if (reminderDate.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
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

  /// Cancel all notifications for a project.
  static Future<void> cancelForProject(
      FlutterLocalNotificationsPlugin plugin, int id) async {
    await plugin.cancel(id);
  }

  /// Cancel all scheduled notifications.
  static Future<void> cancelAll(
      FlutterLocalNotificationsPlugin plugin) async {
    await plugin.cancelAll();
  }
}