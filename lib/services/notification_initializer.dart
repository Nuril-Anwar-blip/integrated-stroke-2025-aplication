import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationInitializer {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Change channel ID to force refresh (avoid stale channel without sound)
  static const String _channelId = 'medication_alarm_channel_v2';
  static const String _channelName = 'Medication Alarms';
  static const String _channelDescription =
      'Loud alarm for medication reminders';
  static const String _sound = 'alarm_sound'; // raw resource name without ext

  /// Call once in main() after WidgetsFlutterBinding.ensureInitialized().
  static Future<void> initialize() async {
    _configureLocalTimeZone();
    await _requestPermissions();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);
    await _createOrUpdateChannel();
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
      await Permission.ignoreBatteryOptimizations.request();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } else {
      await Permission.notification.request();
    }
  }

  static void _configureLocalTimeZone() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);
  }

  static Future<void> _createOrUpdateChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(_sound),
      enableVibration: true,
      showBadge: true,
    );
    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(channel);
    }
  }

  /// Schedule loud alarm at next occurrence of [timeOfDay].
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay timeOfDay,
    String payload = '',
  }) async {
    final scheduled = _nextInstance(timeOfDay);
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(_sound),
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      styleInformation: DefaultStyleInformation(true, true),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  static tz.TZDateTime _nextInstance(TimeOfDay timeOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Immediate alarm to test sound.
  static Future<void> showTestAlarmNow() async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(_sound),
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      ticker: 'MedicationAlarm',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      99999,
      'Tes Alarm',
      'Alarm berbunyi sekarang',
      details,
      payload: 'test_alarm',
    );
  }

  /// Recreate channel after sound change.
  static Future<void> recreateChannel() => _createOrUpdateChannel();

  static Future<void> cancel(int id) => _plugin.cancel(id);
}
