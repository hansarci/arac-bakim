/// Firestore'a yazarken artık Türkçe alan adları kullanılıyor (Orman Muhasebe'deki
/// gibi). Ama daha önce İngilizce alan adlarıyla kaydedilmiş veriler (örn. Ford
/// Courier'ın geçmişi) kaybolmasın diye fromJson hem yeni Türkçe hem eski İngilizce
/// anahtarları okuyabiliyor. toJson ise sadece yeni Türkçe anahtarları yazıyor —
/// yani bir kayıt her güncellendiğinde otomatik olarak yeni formata geçiyor.

class HistoryItem {
  String cat; // örn. "Motor", "Fren Sistemi", "Alt Takım / Rot"
  String sub; // yapılan işlem(ler), " / " ile ayrılmış
  int km; // işlem km/saat değeri (0 ise "—" gösterilir)
  String date; // GG/AA/YYYY

  HistoryItem({
    required this.cat,
    required this.sub,
    required this.km,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'kategori': cat,
        'aciklama': sub,
        'km': km,
        'tarih': date,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        cat: json['kategori'] ?? json['cat'] ?? '',
        sub: json['aciklama'] ?? json['sub'] ?? '',
        km: json['km'] ?? 0,
        date: json['tarih'] ?? json['date'] ?? '—',
      );
}

/// Kalem bazlı bakım kaydı (örn. Triger'in en son yapıldığı km)
class MaintenanceRecord {
  int lastKm;
  MaintenanceRecord({required this.lastKm});

  Map<String, dynamic> toJson() => {'sonKm': lastKm};
  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) =>
      MaintenanceRecord(lastKm: json['sonKm'] ?? json['lastKm'] ?? 0);
}

class Vehicle {
  String id;
  String name;
  String plate;
  String type; // Otomobil, Motosiklet, Kamyonet, Kamyon, Pikap, Traktör, Römork, İş Makinesi, Diğer
  int km;
  String unit; // 'km' veya 'saat'
  int? modelYear;
  int age; // yıl yaşında (model yılından hesaplanır)
  String? lastInspectionDate; // GG/AA/YYYY
  String? inspectionInterval; // "1 Yıl", "2 Yıl", "3 Yıl"
  Map<String, MaintenanceRecord> maintenanceRecords;
  List<HistoryItem> history;

  Vehicle({
    required this.id,
    required this.name,
    required this.plate,
    required this.type,
    required this.km,
    required this.unit,
    this.modelYear,
    this.age = 0,
    this.lastInspectionDate,
    this.inspectionInterval,
    Map<String, MaintenanceRecord>? maintenanceRecords,
    List<HistoryItem>? history,
  })  : maintenanceRecords = maintenanceRecords ?? {},
        history = history ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'isim': name,
        'plaka': plate,
        'tip': type,
        'km': km,
        'birim': unit,
        'modelYili': modelYear,
        'yas': age,
        'sonMuayeneTarihi': lastInspectionDate,
        'muayeneAraligi': inspectionInterval,
        'bakimKayitlari':
            maintenanceRecords.map((k, v) => MapEntry(k, v.toJson())),
        'gecmis': history.map((h) => h.toJson()).toList(),
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'],
        name: json['isim'] ?? json['name'],
        plate: json['plaka'] ?? json['plate'],
        type: json['tip'] ?? json['type'],
        km: json['km'] ?? 0,
        unit: json['birim'] ?? json['unit'] ?? 'km',
        modelYear: json['modelYili'] ?? json['modelYear'],
        age: json['yas'] ?? json['age'] ?? 0,
        lastInspectionDate: json['sonMuayeneTarihi'] ?? json['lastInspectionDate'],
        inspectionInterval: json['muayeneAraligi'] ?? json['inspectionInterval'],
        maintenanceRecords:
            (json['bakimKayitlari'] ?? json['maintenanceRecords'] as Map?)?.map(
                  (k, v) => MapEntry(
                      k as String, MaintenanceRecord.fromJson(Map<String, dynamic>.from(v))),
                ) ??
                {},
        history: ((json['gecmis'] ?? json['history']) as List?)
                ?.map((h) => HistoryItem.fromJson(Map<String, dynamic>.from(h)))
                .toList() ??
            [],
      );
}
