import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';

/// Şimdilik cihaz içi (SharedPreferences) saklama kullanılıyor — Kutur M3'teki gibi
/// Firebase'e bağlamak istersen bu servisi Firestore çağrılarıyla değiştirmen yeterli,
/// geri kalan ekranlar bu servisin arayüzüne bağlı olduğu için etkilenmez.
class StorageService {
  static const _key = 'vehicles_v1';

  Future<List<Vehicle>> loadVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => Vehicle.fromJson(e)).toList();
  }

  Future<void> saveVehicles(List<Vehicle> vehicles) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(vehicles.map((v) => v.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
