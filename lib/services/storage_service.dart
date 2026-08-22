import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle.dart';

/// Firestore üzerinde saklama — Orman Muhasebe'deki gibi kullanıcı girişi (auth)
/// yok, bu uygulamayı sadece sen kullanacağın için tek bir sabit belgede tutuluyor.
///
/// Saha koşullarında internetsiz çalışabilmesi için:
///  - main.dart'ta Firestore'un cihaz içi önbelleği (persistence) açık
///  - saveVehicles bilerek "gönder ve unut" (fire-and-forget) çalışır, ağ
///    cevabını beklemez — bağlantı olmadan da UI hiç takılmadan devam eder
class StorageService {
  final _doc = FirebaseFirestore.instance.collection('app_data').doc('vehicles');

  Future<List<Vehicle>> loadVehicles() async {
    final doc = await _doc.get();
    if (!doc.exists) return [];
    final data = doc.data();
    final list = data?['vehicles'] as List?;
    if (list == null) return [];
    return list
        .map((e) => Vehicle.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Bilerek await edilmiyor — internet olmasa bile UI beklemeden devam eder,
  /// bağlantı geri geldiğinde Firestore kendi arka planda senkronize eder.
  void saveVehicles(List<Vehicle> vehicles) {
    _doc.set({
      'vehicles': vehicles.map((v) => v.toJson()).toList(),
    }).catchError((_) {
      // Sessizce yut — offline'da normal, bağlantı gelince kendiliğinden senkronize olur
    });
  }
}
