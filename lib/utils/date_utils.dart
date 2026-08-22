/// GG/AA/YYYY formatındaki tarih stringlerini işleyen yardımcılar.
/// HTML mockup'taki calcNextInspection / daysUntil fonksiyonlarının birebir karşılığı.

DateTime? parseTrDate(String? s) {
  if (s == null || s.isEmpty) return null;
  final parts = s.split('/');
  if (parts.length != 3) return null;
  final dd = int.tryParse(parts[0]);
  final mm = int.tryParse(parts[1]);
  final yyyy = int.tryParse(parts[2]);
  if (dd == null || mm == null || yyyy == null) return null;
  return DateTime(yyyy, mm, dd);
}

String formatTrDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

String todayTrDate() => formatTrDate(DateTime.now());

/// Son muayene tarihi + tekrar aralığına (örn. "2 Yıl") göre gelecek muayene tarihini hesaplar
String? calcNextInspection(String? lastDateStr, String? intervalStr) {
  final last = parseTrDate(lastDateStr);
  if (last == null || intervalStr == null) return null;
  final match = RegExp(r'\d+').firstMatch(intervalStr);
  if (match == null) return null;
  final years = int.parse(match.group(0)!);
  final next = DateTime(last.year + years, last.month, last.day);
  return formatTrDate(next);
}

/// Bir tarihin bugüne göre kaç gün kaldığını/geçtiğini hesaplar (negatifse geçmiş demektir)
int? daysUntil(String? dateStr) {
  final target = parseTrDate(dateStr);
  if (target == null) return null;
  final today = DateTime.now();
  final todayMidnight = DateTime(today.year, today.month, today.day);
  return target.difference(todayMidnight).inDays;
}
