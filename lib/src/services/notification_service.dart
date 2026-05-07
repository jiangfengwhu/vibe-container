import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class ScheduledNotification {
  const ScheduledNotification({
    required this.appId,
    required this.title,
    required this.body,
    required this.time,
  });

  final String appId;
  final String title;
  final String body;
  final DateTime time;

  Map<String, Object?> toJson() => <String, Object?>{
    'appId': appId,
    'title': title,
    'body': body,
    'time': time.toUtc().toIso8601String(),
  };
}

class NotificationService {
  NotificationService();

  final List<ScheduledNotification> _scheduled = <ScheduledNotification>[];
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  List<ScheduledNotification> get scheduled =>
      List<ScheduledNotification>.unmodifiable(_scheduled);

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    timezone_data.initializeTimeZones();
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
    );
    await _plugin.initialize(settings: initializationSettings);
    _initialized = true;
  }

  Future<Map<String, Object?>> requestPermission() async {
    await initialize();
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final apple = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final macOS = await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return <String, Object?>{'granted': android ?? apple ?? macOS ?? true};
  }

  Future<Map<String, Object?>> getPermissionStatus() async {
    await initialize();
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.areNotificationsEnabled();
    return <String, Object?>{'granted': android ?? true};
  }

  Future<Map<String, Object?>> schedule({
    int? id,
    required String appId,
    required String title,
    required String body,
    required DateTime time,
  }) async {
    await initialize();
    final notification = ScheduledNotification(
      appId: appId,
      title: title,
      body: body,
      time: time,
    );
    _scheduled.add(notification);
    final notificationId = id ?? time.microsecondsSinceEpoch.remainder(1 << 31);
    await _plugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: timezone.TZDateTime.from(time, timezone.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'local_app_workbench_runtime',
          '本地应用工作台',
          channelDescription: 'Mini app runtime notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return <String, Object?>{
      'scheduled': true,
      'id': notificationId,
      'notification': notification.toJson(),
      'note': 'Scheduled through the host runtime notification service.',
    };
  }

  Future<Map<String, Object?>> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
    return <String, Object?>{'ok': true};
  }

  Future<Map<String, Object?>> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
    _scheduled.clear();
    return <String, Object?>{'ok': true};
  }
}
