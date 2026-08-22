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
        'cat': cat,
        'sub': sub,
        'km': km,
        'date': date,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        cat: json['cat'] ?? '',
        sub: json['sub'] ?? '',
        km: json['km'] ?? 0,
        date: json['date'] ?? '—',
      );
}

/// Kalem bazlı bakım kaydı (örn. Triger'in en son yapıldığı km)
class MaintenanceRecord {
  int lastKm;
  MaintenanceRecord({required this.lastKm});

  Map<String, dynamic> toJson() => {'lastKm': lastKm};
  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) =>
      MaintenanceRecord(lastKm: json['lastKm'] ?? 0);
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
        'name': name,
        'plate': plate,
        'type': type,
        'km': km,
        'unit': unit,
        'modelYear': modelYear,
        'age': age,
        'lastInspectionDate': lastInspectionDate,
        'inspectionInterval': inspectionInterval,
        'maintenanceRecords':
            maintenanceRecords.map((k, v) => MapEntry(k, v.toJson())),
        'history': history.map((h) => h.toJson()).toList(),
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'],
        name: json['name'],
        plate: json['plate'],
        type: json['type'],
        km: json['km'] ?? 0,
        unit: json['unit'] ?? 'km',
        modelYear: json['modelYear'],
        age: json['age'] ?? 0,
        lastInspectionDate: json['lastInspectionDate'],
        inspectionInterval: json['inspectionInterval'],
        maintenanceRecords: (json['maintenanceRecords'] as Map?)?.map(
              (k, v) => MapEntry(
                  k as String, MaintenanceRecord.fromJson(v)),
            ) ??
            {},
        history: (json['history'] as List?)
                ?.map((h) => HistoryItem.fromJson(h))
                .toList() ??
            [],
      );
}
