import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:positive_phill/services/affirmations_service.dart';

class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  static const int _dailyNotificationId = 1001;
  static const String _channelId = 'daily_affirmations';
  static const String _channelName = 'Daily Affirmations';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final AffirmationsService _affirmationsService = AffirmationsService();
  bool _initialized = false;

  Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      final String tzName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(tzName));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.requestNotificationsPermission();
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
        }
      }

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationsService init failed: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> scheduleDailyAffirmation({required TimeOfDay time}) async {
    if (kIsWeb) return;
    try {
      await init();
      final pack = _affirmationsService.getDailyPack();
      final affirmation = pack.isNotEmpty ? pack.first.text : _affirmationsService.getDailyTheme();
      final scheduledDate = _nextInstanceOfTime(time);

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Daily affirmation reminders',
        importance: Importance.high,
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _plugin.zonedSchedule(
        id: _dailyNotificationId,
        title: 'Positive Phill',
        body: affirmation,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('scheduleDailyAffirmation failed: $e');
    }
  }

  Future<void> cancelDailyAffirmation() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(id: _dailyNotificationId);
    } catch (e) {
      debugPrint('cancelDailyAffirmation failed: $e');
    }
  }
}
