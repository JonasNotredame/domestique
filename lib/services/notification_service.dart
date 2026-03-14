import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/todo.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _available = true;

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(settings);

      await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

      await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

      await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    } on MissingPluginException {
      _available = false;
    }
  }

  static int _baseIdForTodo(String todoId) {
    return todoId.hashCode & 0x3fffffff;
  }

  static NotificationDetails _details(TodoImportance importance) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'todo_reminders',
        'Todo Reminders',
        channelDescription: 'Reminders based on todo importance',
        importance: importance == TodoImportance.high
            ? Importance.max
            : Importance.defaultImportance,
        priority: importance == TodoImportance.high
            ? Priority.high
            : Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
  }

  static tz.TZDateTime _nextEightAM([DateTime? from]) {
    final now = tz.TZDateTime.from(from ?? DateTime.now(), tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> scheduleForTodo(TodoItem todo) async {
    if (!_available) return;
    await cancelForTodo(todo.id);

    if (todo.isDone) return;

    final baseId = _baseIdForTodo(todo.id);
    final details = _details(todo.importance);

    if (todo.importance == TodoImportance.high) {
      await _plugin.zonedSchedule(
        baseId,
        'High Priority To-Do',
        todo.title,
        _nextEightAM(),
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return;
    }

    if (todo.importance == TodoImportance.low) {
      await _plugin.zonedSchedule(
        baseId,
        'Low Priority To-Do',
        todo.title,
        _nextEightAM(todo.createdAt),
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      return;
    }

    var at = _nextEightAM();
    for (var i = 0; i < 180; i++) {
      await _plugin.zonedSchedule(
        baseId + i,
        'Medium Priority To-Do',
        todo.title,
        at,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      at = at.add(const Duration(days: 2));
    }
  }

  static Future<void> cancelForTodo(String todoId) async {
    if (!_available) return;
    final baseId = _baseIdForTodo(todoId);
    for (var i = 0; i < 180; i++) {
      await _plugin.cancel(baseId + i);
    }
  }
}
