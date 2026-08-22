import '../models/vehicle.dart';

/// Her kural: yapılan işlem metninde geçen anahtar kelime + standart km aralığı.
/// Yeni bir kalem eklemek için buraya bir MaintenanceRule eklemek yeterli.
class MaintenanceRule {
  final String id;
  final List<String> keywords;
  final int interval;
  final String label;

  const MaintenanceRule({
    required this.id,
    required this.keywords,
    required this.interval,
    required this.label,
  });
}

const List<MaintenanceRule> maintenanceRules = [
  MaintenanceRule(
    id: 'triger',
    keywords: ['triger'],
    interval: 90000,
    label: 'Triger değişimi',
  ),
];

enum MaintenanceAlertType { upcoming, overdue }

class MaintenanceAlert {
  final MaintenanceAlertType type;
  final String label;
  final int amount;
  MaintenanceAlert(
      {required this.type, required this.label, required this.amount});
}

/// Bir aracın km bazlı bakım uyarılarını hesaplar: yaklaşan (<=10.000 km kala) veya gecikmiş.
/// İlk kayıt girilmeden bu kalem için tahmin/uyarı üretilmez.
List<MaintenanceAlert> getMaintenanceAlerts(Vehicle v) {
  if (v.unit != 'km') return [];
  final alerts = <MaintenanceAlert>[];
  for (final rule in maintenanceRules) {
    final rec = v.maintenanceRecords[rule.id];
    if (rec == null) continue;
    final target = rec.lastKm + rule.interval;
    final diff = target - v.km;
    if (diff <= 0) {
      alerts.add(MaintenanceAlert(
        type: MaintenanceAlertType.overdue,
        label: rule.label,
        amount: diff.abs(),
      ));
    } else if (diff <= 10000) {
      alerts.add(MaintenanceAlert(
        type: MaintenanceAlertType.upcoming,
        label: rule.label,
        amount: diff,
      ));
    }
  }
  return alerts;
}

/// Yapılan işlem etiketleri arasında bir bakım kuralıyla eşleşen varsa,
/// o kalemin son km'sini günceller.
void updateMaintenanceRecords(Vehicle v, List<String> tags, int? kmNum) {
  if (tags.isEmpty) return;
  final refKm = kmNum ?? v.km;
  for (final tag in tags) {
    final lower = tag.toLowerCase();
    for (final rule in maintenanceRules) {
      if (rule.keywords.any((k) => lower.contains(k))) {
        v.maintenanceRecords[rule.id] = MaintenanceRecord(lastKm: refKm);
      }
    }
  }
}
