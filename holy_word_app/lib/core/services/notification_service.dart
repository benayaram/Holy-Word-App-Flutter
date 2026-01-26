import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../features/bible/presentation/reading_plans/plan_detail_screen.dart';
import '../../main.dart'; // To access navigatorKey

class ReminderModel {
  final int id;
  final String planId; // The plan this reminder belongs to
  final int hour;
  final int minute;
  final bool isEnabled;

  ReminderModel({
    required this.id,
    required this.planId,
    required this.hour,
    required this.minute,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'planId': planId,
        'hour': hour,
        'minute': minute,
        'isEnabled': isEnabled,
      };

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
        id: json['id'],
        planId: json['planId'],
        hour: json['hour'],
        minute: json['minute'],
        isEnabled: json['isEnabled'] ?? true,
      );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String _prefRemindersKey = 'saved_reminders_list';

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final dynamic rawName = await FlutterTimezone.getLocalTimezone();
      String timeZoneName = rawName.toString();

      // Fix for some devices returning verbose TimezoneInfo string
      if (timeZoneName.startsWith("TimezoneInfo(")) {
        // Extract "Asia/Kolkata" from "TimezoneInfo(Asia/Kolkata, ...)"
        final parts = timeZoneName.split(',');
        if (parts.isNotEmpty) {
          timeZoneName = parts[0].replaceAll("TimezoneInfo(", "").trim();
        }
      }

      debugPrint("Raw Timezone: $rawName");
      debugPrint("Sanitized Timezone: $timeZoneName");

      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint("Failed to set local location: $e");
      // Fallback: Try hardcoded 'Asia/Kolkata' if detection fails (since user seems to be in India)
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
        debugPrint("Fallback to Asia/Kolkata successful");
      } catch (fallbackError) {
        debugPrint("Fallback failed too");
      }
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
        if (details.payload != null) {
          final planId = details.payload!;
          // Navigate to Plan Detail
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => PlanDetailScreen(
                planId: planId,
                planName:
                    "Reading Plan", // Generic name, detail screen will load data
              ),
            ),
          );
        }
      },
    );

    // Create Channel explicitly
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation
          .createNotificationChannel(const AndroidNotificationChannel(
        'daily_reading_channel',
        'Daily Reading Reminders',
        description: 'Reminders to read your daily plan',
        importance: Importance.max,
      ));
    }

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    // Android
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final notifGranted =
          await androidImplementation.requestNotificationsPermission();
      final alarmGranted =
          await androidImplementation.requestExactAlarmsPermission();

      return (notifGranted ?? false) && (alarmGranted ?? true);
    }

    // iOS
    final iosImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  // --- Multi-Reminder Logic ---

  Future<List<ReminderModel>> getAllReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_prefRemindersKey);
    if (jsonStr == null) return [];

    final List<dynamic> jsonList = json.decode(jsonStr);
    return jsonList.map((e) => ReminderModel.fromJson(e)).toList();
  }

  Future<List<ReminderModel>> getRemindersForPlan(String planId) async {
    final all = await getAllReminders();
    return all.where((r) => r.planId == planId).toList();
  }

  Future<void> addReminder(String planId, TimeOfDay time) async {
    await init();

    // Create unique ID mostly unique to time/plan
    final now = DateTime.now();
    final uniqueId = now.millisecondsSinceEpoch ~/ 1000;

    final newReminder = ReminderModel(
      id: uniqueId,
      planId: planId,
      hour: time.hour,
      minute: time.minute,
    );

    // Save
    final reminders = await getAllReminders();
    reminders.add(newReminder);
    await _saveReminders(reminders);

    // Schedule
    await _scheduleNotification(newReminder);
  }

  Future<void> deleteReminder(int id) async {
    await _notificationsPlugin.cancel(id);

    final reminders = await getAllReminders();
    reminders.removeWhere((r) => r.id == id);
    await _saveReminders(reminders);
  }

  Future<void> _saveReminders(List<ReminderModel> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = reminders.map((r) => r.toJson()).toList();
    await prefs.setString(_prefRemindersKey, json.encode(jsonList));
  }

  Future<void> _scheduleNotification(ReminderModel reminder) async {
    if (!reminder.isEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminder.hour,
      reminder.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint("--- SCHEDULING REMINDER ---");
    debugPrint("Current Time (Local): $now");
    debugPrint("Desired Time: ${reminder.hour}:${reminder.minute}");
    debugPrint("Scheduled For: $scheduledDate");
    debugPrint("TimeZone: ${now.location}");
    debugPrint("---------------------------");

    await _notificationsPlugin.zonedSchedule(
      reminder.id,
      'Daily Bible Reading',
      'Time to read your daily portion!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reading_channel',
          'Daily Reading Reminders',
          channelDescription: 'Reminders to read your daily plan',
          importance: Importance.max,
          priority: Priority.high,
          tag: reminder.planId,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: reminder.planId,
    );
    debugPrint('Scheduled reminder ID ${reminder.id} successfully');
  }

  // Reschedule all on boot (call this from main or boot receiver if native side set up)
  Future<void> rescheduleAll() async {
    await init();
    final reminders = await getAllReminders();
    for (var r in reminders) {
      if (r.isEnabled) await _scheduleNotification(r);
    }
  }
}
