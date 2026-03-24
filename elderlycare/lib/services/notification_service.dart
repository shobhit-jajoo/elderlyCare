import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

// 🛑 TOP-LEVEL FUNCTION: Handles background button presses (Snooze / Taken)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  // 1. Re-initialize Timezones for the background isolate
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

  // 2. Initialize the plugin locally inside the isolate
  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

  final actionId = response.actionId;
  final id = response.id ?? 0;
  final payload = response.payload ?? "Medicine";

  print("Background Action Triggered: $actionId for $payload");

  // 🔥 THE KILL COMMAND: Forcefully stops the looping sound immediately
  await notifications.cancel(id);

  if (actionId == 'snooze') {
    print("SNOOZE PRESSED: Rescheduling $payload in 5 minutes");
    await NotificationService.scheduleSnooze(id, payload);
  } else if (actionId == 'taken') {
    print("MEDS TAKEN: Alarm fully stopped.");
  }
}

// 🛑 TOP-LEVEL FUNCTION: Used strictly by AndroidAlarmManager
@pragma('vm:entry-point')
void alarmCallback() async {
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifications.initialize(const InitializationSettings(android: android));

  final insistentFlag = Int32List.fromList(<int>[4]);

  await notifications.show(
    999,
    "Medicine Reminder",
    "Time to take your medicine!",
    NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_manager_channel_v2',
        'Alarm Manager Reminders',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        playSound: true,
        additionalFlags: insistentFlag,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        sound: const RawResourceAndroidNotificationSound('med_sound'), 
      ),
    ),
  );
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await notifications.initialize(
      const InitializationSettings(android: android),
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        notificationTapBackground(response);
      },
    );
  }

  /// 🛡️ Ask for permissions (CALL THIS FROM YOUR UI AFTER A 1-SECOND DELAY)
  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  /// 🔔 BASIC NOTIFICATION 
  static Future<void> showNotification(int id, String title, String body,
      {bool withSound = true}) async {
    await notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'basic_channel',
          'Basic Reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: withSound,
        ),
      ),
    );
  }

  /// ⏰ ALARM MANAGER 
  static Future<void> scheduleMedicineAlarm(int hour, int minute) async {
    final now = DateTime.now();
    DateTime scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

    await AndroidAlarmManager.oneShotAt(
      scheduled,
      scheduled.millisecondsSinceEpoch ~/ 1000,
      alarmCallback,
      exact: true,
      wakeup: true,
    );
  }

  /// 💊 SMART SCHEDULER 
  static Future<void> scheduleMedicine(
      int id, int hour, int minute, String name) async {
    final scheduledTime = _nextInstance(hour, minute);
    print("Scheduled $name for $scheduledTime");

    await _triggerAlarm(id, name, scheduledTime);
  }

  /// 💤 SNOOZE ALARM (5 minutes from now)
  static Future<void> scheduleSnooze(int id, String name) async {
    final scheduledTime =
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 5));
    print("Snoozed $name for $scheduledTime");

    await _triggerAlarm(id, name, scheduledTime);
  }

  /// 🔔 CORE SMART ALARM LOGIC
  static Future<void> _triggerAlarm(
      int id, String name, tz.TZDateTime scheduledTime) async {
      
    final nameLower = name.toLowerCase();
    bool isWater = nameLower.contains('water');
    bool isExercise = nameLower.contains('exercise');

    String channelId = 'med_channel_v3'; // Bumped ID to refresh Android's cache
    String channelName = 'Medicine Alarms';
    String title = 'Medicine Reminder';
    String body = 'Time to take: $name';
    String soundFile = 'med_sound';
    bool loopSound = true; 

    if (isWater) {
      channelId = 'water_channel_v3';
      channelName = 'Water Reminders';
      title = 'Hydration Reminder 💧';
      body = 'Time to drink a glass of water!';
      soundFile = 'water_sound';
      loopSound = false; 
    } 
    else if (isExercise) {
      channelId = 'exercise_channel_v3';
      channelName = 'Exercise Reminders';
      title = 'Exercise Time! 🏃';
      body = 'Time to get up and move!';
      soundFile = 'exercise_sound';
      loopSound = false; 
    }

    final insistentFlag = Int32List.fromList(<int>[4]);

    List<AndroidNotificationAction>? notificationActions;
    if (!isWater && !isExercise) {
      notificationActions = <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'taken',
          '✅ Meds Taken',
          cancelNotification: true, // Dismisses the visual notification
        ),
        const AndroidNotificationAction(
          'snooze',
          '💤 Snooze (5m)',
          cancelNotification: true,
        ),
      ];
    }

    await notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId, 
          channelName,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          additionalFlags: loopSound ? insistentFlag : null, 
          audioAttributesUsage: AudioAttributesUsage.alarm,
          sound: RawResourceAndroidNotificationSound(soundFile), 
          actions: notificationActions,
        ),
      ),
      payload: name, 
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 🔁 Helper
  static tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}