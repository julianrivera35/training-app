import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Thin wrapper around local notifications, used to alert the user when a
/// rest timer finishes while the app is in the background or closed.
/// Everything is wrapped in try/catch so a permission denial or platform
/// hiccup never breaks the in-app timer.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const int _restId = 1001;

  static Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: false,
        requestSoundPermission: true,
      );
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(iOS: ios, android: android),
      );
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService.init failed: $e');
    }
  }

  /// Schedules a one-shot notification [seconds] from now.
  static Future<void> scheduleRestEnd(int seconds, String exercise) async {
    if (!_ready || seconds <= 0) return;
    try {
      final when = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
      await _plugin.zonedSchedule(
        _restId,
        '✅ ¡Descanso terminado!',
        exercise.isEmpty ? 'A la siguiente serie 💪' : 'Sigue: $exercise',
        when,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true),
          android: AndroidNotificationDetails(
            'rest_timer', 'Timer de descanso',
            channelDescription: 'Avisa cuando termina el descanso entre series',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('NotificationService.scheduleRestEnd failed: $e');
    }
  }

  static Future<void> cancelRestEnd() async {
    try {
      await _plugin.cancel(_restId);
    } catch (_) {}
  }
}
