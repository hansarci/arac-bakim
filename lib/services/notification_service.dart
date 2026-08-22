import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../models/vehicle.dart';
import '../utils/date_utils.dart';

/// Muayene tarihine 10 gün ve 5 gün kala, o günün öğlen 12'sinde birer defaya
/// mahsus bildirim planlar (anlık gönderim değil, gerçek zamanlı planlama).
/// Muayene tarihi zaten geçmişse hiçbir bildirim planlanmaz — "parası yoktur,
/// yaptıramamıştır ama geçtiğini zaten biliyordur" mantığıyla.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    // Android 13+ (API 33) bildirim izni gerektirir — kullanıcıdan iste
    await _plugin
        .resolvePlatformSpecificImplementation
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Bir aracın muayene hatırlatmalarını (10 gün ve 5 gün kala) yeniden planlar.
  /// Muayene tarihi değiştiğinde (yeni araç, yeni tekrar aralığı, "muayene
  /// yaptım" onayı vb.) her seferinde çağrılır — önce eskisini iptal edip
  /// güncel tarihe göre yeniden kurar.
  Future<void> scheduleInspectionReminders(Vehicle v) async {
    await init();

    final tenDaysId = ('${v.id}_10').hashCode;
    final fiveDaysId = ('${v.id}_5').hashCode;
    await _plugin.cancel(tenDaysId);
    await _plugin.cancel(fiveDaysId);

    final nextStr = calcNextInspection(v.lastInspectionDate, v.inspectionInterval);
    if (nextStr == null) return;
    final nextDate = parseTrDate(nextStr);
    if (nextDate == null) return;

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    if (nextDate.isBefore(todayMidnight)) {
      return; // muayene zaten geçmiş — bildirim planlanmaz
    }

    await _scheduleAt(tenDaysId, v, nextDate.subtract(const Duration(days: 10)), nextStr, 10);
    await _scheduleAt(fiveDaysId, v, nextDate.subtract(const Duration(days: 5)), nextStr, 5);
  }

  Future<void> _scheduleAt(
      int id, Vehicle v, DateTime day, String nextStr, int daysBefore) async {
    final target = DateTime(day.year, day.month, day.day, 12, 0);
    if (target.isBefore(DateTime.now())) {
      return; // o günün saati zaten geçmiş — geç kalınmış bildirim gönderilmez
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
    );
  }
}
