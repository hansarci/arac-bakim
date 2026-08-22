import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../models/vehicle.dart';
import '../utils/date_utils.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    _initialized = true;
  }

  /// Bir aracın muayene hatırlatmalarını (10 gün ve 5 gün kala) yeniden planlar.
  Future<void> scheduleInspectionReminders(Vehicle v) async {
    await init();

    final int tenDaysId = ('${v.id}_10').hashCode;
    final int fiveDaysId = ('${v.id}_5').hashCode;
    await _plugin.cancel(tenDaysId);
    await _plugin.cancel(fiveDaysId);

    final String? nextStr = calcNextInspection(v.lastInspectionDate, v.inspectionInterval);
    if (nextStr == null) return;
    final DateTime? nextDate = parseTrDate(nextStr);
    if (nextDate == null) return;

    final DateTime today = DateTime.now();
    final DateTime todayMidnight = DateTime(today.year, today.month, today.day);
    if (nextDate.isBefore(todayMidnight)) {
      return;
    }

    await _scheduleAt(tenDaysId, v, nextDate.subtract(const Duration(days: 10)), nextStr, 10);
    await _scheduleAt(fiveDaysId, v, nextDate.subtract(const Duration(days: 5)), nextStr, 5);
  }

  Future<void> _scheduleAt(int id, Vehicle v, DateTime day, String nextStr, int daysBefore) async {
    final DateTime target = DateTime(day.year, day.month, day.day, 12, 0);
    if (target.isBefore(DateTime.now())) {
      return;
    }

    await _plugin.zonedSchedule(
      id,
      'Muayene Hatırlatması',
      '${v.name} (${v.plate}) — muayene tarihine $daysBefore gün kaldı ($nextStr)',
      tz.TZDateTime.from(target, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'inspection_channel',
          'Muayene Hatırlatmaları',
          channelDescription: 'Araç muayene tarihi yaklaşınca bildirir',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
