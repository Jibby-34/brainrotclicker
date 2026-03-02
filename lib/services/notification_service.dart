import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Schedules "come collect your brains" reminders at 9 AM, 1 PM, 5 PM, and
/// 9 PM every day (every four hours between 9 AM and 9 PM).
///
/// Call [init] once at app start, then call [scheduleReminders] with the
/// latest brain count whenever the app opens or goes to the background.
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'brain_reminders';
  static const _channelName = 'Brain Reminders';
  static const _channelDesc = 'Periodic reminders to collect your brains';

  /// Hours at which reminders fire: 9 AM, 1 PM, 5 PM, 9 PM.
  static const _reminderHours = [9, 13, 17, 21];

  // ── Init ──────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;

    // Set up timezone database and pin the device's local timezone.
    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Request POST_NOTIFICATIONS permission on Android 13+.
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  // ── Scheduling ────────────────────────────────────────────────────────────

  /// Cancels all pending reminders and reschedules them with [brainCount]
  /// embedded in the notification body.
  static Future<void> scheduleReminders(double brainCount) async {
    if (!_initialized) return;

    await _plugin.cancelAll();

    final formatted = _formatNumber(brainCount);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < _reminderHours.length; i++) {
      final scheduledDate = _nextInstanceOf(_reminderHours[i], now);
      await _plugin.zonedSchedule(
        id: i,
        title: 'Brainrot Clicker 🧠',
        body: 'You have $formatted brains waiting! Come collect more!',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the next [tz.TZDateTime] that falls on [hour]:00 local time.
  /// If today's slot has already passed the next occurrence is tomorrow.
  static tz.TZDateTime _nextInstanceOf(int hour, tz.TZDateTime now) {
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
    );
    if (candidate.isBefore(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  static String _formatNumber(double n) {
    if (n >= 1e12) return '${(n / 1e12).toStringAsFixed(1)}T';
    if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}B';
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}
