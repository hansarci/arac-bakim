import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/vehicle.dart';
import '../utils/date_utils.dart';

/// Muayene tarihine 7 gün veya daha az kaldığında (ya da tarih zaten geçtiyse)
/// cihaza gerçek bir push bildirimi gönderir. Uygulama her açıldığında
/// ve her araç/işlem eklendiğinde checkAndNotify çağrılır.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    // Android 13+ (API 33) bildirim izni gerektirir — kullanıcıdan iste
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> checkAndNotify(List<Vehicle> vehicles) async {
    await init();
    for (final v in vehicles) {
      final nextStr = calcNextInspection(v.lastInspectionDate, v.inspectionInterval);
      if (nextStr == null) continue;
      final diff = daysUntil(nextStr);
      if (diff == null || diff > 7) continue;

      final overdue = diff < 0;
      final title = 'Muayene Hatırlatması';
      final body = overdue
          ? '${v.name} (${v.plate}) — muayene tarihi ${diff.abs()} gün geçti ($nextStr)'
          : '${v.name} (${v.plate}) — muayene tarihi $nextStr';

      await _plugin.show(
        v.id.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'inspection_channel',
            'Muayene Hatırlatmaları',
            channelDescription: 'Araç muayene tarihi yaklaştığında/geçtiğinde bildirir',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  }
}
