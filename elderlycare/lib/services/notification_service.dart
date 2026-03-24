import 'dart:io';
import 'dart:typed_data'; // ✅ Required for Int32List (Looping Alarm)
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

// 🛑 TOP-LEVEL FUNCTION: Handles background button presses (Snooze / Taken)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  // Background isolates need timezones initialized again!
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

  final actionId = response.actionId;
  final id = response.id ?? 0;
  final payload = response.payload ?? "Medicine";

  if (actionId == 'snooze') {
    print("SNOOZE PRESSED: Rescheduling in 5 minutes");
    await NotificationService.scheduleSnooze(id, payload);
  } else if (actionId == 'taken') {
    print("MEDS TAKEN: Alarm Dismissed");
    // Doing nothing simply lets the notification clear and the sound stop.
  }
}

// 🛑 TOP-LEVEL FUNCTION: Used strictly by AndroidAlarmManager
@pragma('vm:entry-point')
void alarmCallback() async {
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');

  await notifications.initialize(
    const InitializationSettings(android: android),
  );

  final insistentFlag = Int32List.fromList(<int>[4]);

  await notifications.show(
    999,
    "Medicine Reminder",
    "Time to take your medicine!",
    NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_manager_channel',
        'Alarm Manager Reminders',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        playSound: true,
        additionalFlags: insistentFlag,
        audioAttributesUsage: AudioAttributesUsage.alarm,
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

    // ✅ Initialize with background handlers for the action buttons
    await notifications.initialize(
      const InitializationSettings(android: android),
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle taps when the app is open in the foreground
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

  /// 🔔 BASIC NOTIFICATION (Quick alert, no looping sound, no buttons)
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

  /// ⏰ ALARM MANAGER (Heavy Background Tasks)
  static Future<void> scheduleMedicineAlarm(int hour, int minute) async {
    final now = DateTime.now();

    DateTime scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    print("Alarm scheduled at: $scheduled");

    await AndroidAlarmManager.oneShotAt(
      scheduled,
      scheduled.millisecondsSinceEpoch ~/ 1000,
      alarmCallback,
      exact: true,
      wakeup: true,
    );
  }

  /// 💊 MEDICINE ALARM (ZonedSchedule with Custom Sound & Buttons)
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

  /// 🔔 CORE ALARM LOGIC (Used by both Medicine and Snooze)
  static Future<void> _triggerAlarm(
      int id, String name, tz.TZDateTime scheduledTime) async {
    final insistentFlag = Int32List.fromList(<int>[4]);

    await notifications.zonedSchedule(
      id,
      "Medicine Reminder",
      "Time to take: $name",
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel_v4', // 🛑 ID changed to force Android to register buttons/sound
          'Medicine Alarms',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          additionalFlags: insistentFlag, // Loops the sound continuously
          audioAttributesUsage: AudioAttributesUsage.alarm, // Uses Alarm volume
          sound: const RawResourceAndroidNotificationSound('alarm_sound'), // ✅ Add alarm_sound.mp3 to res/raw/
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'taken',
              '✅ Meds Taken',
              cancelNotification: true, // Stops the alarm instantly
            ),
            const AndroidNotificationAction(
              'snooze',
              '💤 Snooze (5m)',
              cancelNotification: true, // Clears this alarm, background task schedules the next
            ),
          ],
        ),
      ),
      payload: name, // Passes medicine name to the background handler for snoozing
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 💧 WATER (Standard repeating interval, no looping sound)
  static Future<void> scheduleWater(int id, int intervalMinutes) async {
    await notifications.periodicallyShow(
      id,
      "Hydration Reminder",
      "Drink water 💧",
      RepeatInterval.everyMinute,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_channel',
          'Water',
          importance: Importance.high,
        ),
      ),
    );
  }

  /// 🏃 EXERCISE
  static Future<void> scheduleExercise() async {
    await scheduleMedicine(200, 8, 0, "Morning Exercise");
    await scheduleMedicine(201, 17, 0, "Evening Exercise");
  }

  /// 🔁 Helper
  static tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}