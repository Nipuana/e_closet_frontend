import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Schedules and cancels local reminder notifications for planned outfits.
/// Each plan owns one reminder; the plan's id maps deterministically to the
/// notification id so toggling/rescheduling is idempotent.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
    'plan_reminders',
    'Plan reminders',
    channelDescription: 'Reminders for outfits you have planned',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  /// Stable, non-negative notification id derived from the plan id.
  int _idFor(String planId) => planId.hashCode & 0x7fffffff;

  Future<void> init() async {
    if (_initialized) return;
    // Notifications are a no-op on desktop/web targets.
    if (kIsWeb) return;

    tzdata.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );
    _initialized = true;
  }

  /// Ask the user for permission to post notifications (Android 13+ / iOS).
  Future<void> requestPermissions() async {
    await init();
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// (Re)schedule the reminder for a plan. Cancels any existing one first so
  /// edits don't stack. Past times are skipped.
  Future<void> schedulePlanReminder({
    required String planId,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await init();
    await cancelPlanReminder(planId);

    if (when.isBefore(DateTime.now())) return;

    // Preserve the absolute instant; the OS fires it at the correct wall time
    // regardless of the device's configured timezone database.
    final scheduled = tz.TZDateTime.from(when, tz.UTC);

    await _plugin.zonedSchedule(
      _idFor(planId),
      title,
      body,
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelPlanReminder(String planId) async {
    await init();
    await _plugin.cancel(_idFor(planId));
  }
}
