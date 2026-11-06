import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A reminder the device shows by itself, without a server (webinars,
/// measurements). Push from the server needs Firebase and is not wired yet.
class Reminder {
  const Reminder({
    required this.key,
    required this.at,
    required this.title,
    required this.body,
    required this.route,
  });

  /// Stable identity, e.g. `webinar:w1:24h`; scheduling again replaces it.
  final String key;
  final DateTime at;
  final String title;
  final String body;
  final String route;
}

abstract interface class ReminderScheduler {
  /// Whether the operating system lets this app show notifications.
  Future<bool> isPermitted();

  Future<bool> requestPermission();

  Future<void> openSystemSettings();

  Future<void> schedule(Reminder reminder);

  Future<void> cancel(String key);

  /// Taps on shown notifications, as in-app routes.
  Stream<String> get taps;
}

/// Stable 31-bit id from a reminder key (Android needs an int).
int reminderId(String key) {
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler._();

  static final instance = LocalReminderScheduler._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();
  bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'reminders',
    'Reminders',
    channelDescription: 'Webinar and measurement reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null) _taps.add(route);
      },
    );
    _ready = true;
  }

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<bool> isPermitted() async {
    await _init();
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          false;
    }
    if (Platform.isIOS) {
      final options = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      return options?.isEnabled ?? false;
    }
    return false;
  }

  @override
  Future<bool> requestPermission() async {
    await _init();
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  @override
  Future<void> openSystemSettings() => ph.openAppSettings();

  @override
  Future<void> schedule(Reminder reminder) async {
    await _init();
    if (!reminder.at.isAfter(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id: reminderId(reminder.key),
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.at, tz.local),
        notificationDetails: const NotificationDetails(
          android: _channel,
          iOS: DarwinNotificationDetails(),
        ),
        // Inexact: no special alarm permission, battery friendly.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: reminder.route,
      );
    } catch (e) {
      debugPrint('Could not schedule ${reminder.key}: $e');
    }
  }

  @override
  Future<void> cancel(String key) async {
    await _init();
    await _plugin.cancel(id: reminderId(key));
  }
}

/// For tests and platforms without notifications: records what would be
/// scheduled.
class RecordingReminderScheduler implements ReminderScheduler {
  RecordingReminderScheduler({this.permitted = true});

  bool permitted;
  final scheduled = <String, Reminder>{};
  bool openedSettings = false;
  final _taps = StreamController<String>.broadcast();

  void simulateTap(String route) => _taps.add(route);

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<bool> isPermitted() async => permitted;

  @override
  Future<bool> requestPermission() async => permitted;

  @override
  Future<void> openSystemSettings() async => openedSettings = true;

  @override
  Future<void> schedule(Reminder reminder) async =>
      scheduled[reminder.key] = reminder;

  @override
  Future<void> cancel(String key) async => scheduled.remove(key);
}
