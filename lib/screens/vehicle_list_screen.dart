import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/formatters.dart';
import '../widgets/add_vehicle_sheet.dart';
import 'vehicle_detail_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final _storage = StorageService();
  List<Vehicle> vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _storage.loadVehicles();
    setState(() {
      vehicles = list;
      _loading = false;
    });
    await NotificationService.instance.checkAndNotify(vehicles);
  }

  Future<void> _persist() async {
    await _storage.saveVehicles(vehicles);
    await NotificationService.instance.checkAndNotify(vehicles);
  }

  Future<void> _openAddVehicle() async {
    final result = await showModalBottomSheet<Vehicle>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddVehicleSheet(),
    );
    if (result != null) {
      setState(() => vehicles.insert(0, result));
      await _persist();
    }
  }

  Future<void> _openDetail(Vehicle v) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: v)),
    );
    // Detay sayfasında işlem eklenmiş/muayene güncellenmiş olabilir — kaydet ve yenile
    setState(() {});
    await _persist();
  }

  List<Map<String, dynamic>> _inspectionAlerts() {
    final alerts = <Map<String, dynamic>>[];
    for (final v in vehicles) {
      final nextStr = calcNextInspection(v.lastInspectionDate, v.inspectionInterval);
      if (nextStr == null) continue;
      final diff = daysUntil(nextStr);
      if (diff == null || diff > 7) continue;
      alerts.add({'vehicle': v, 'nextStr': nextStr, 'diff': diff});
    }
    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _inspectionAlerts();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
            : Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Araçlarım',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text)),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.bgElev2,
                                border: Border.all(color: AppColors.line),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.search, color: AppColors.orange, size: 18),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.line),
                      Expanded(
                        child: vehicles.isEmpty
                            ? _emptyState()
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                                children: [
                                  for (final alert in alerts) _AlertBanner(data: alert),
                                  for (final v in vehicles)
                                    _VehicleCard(
                                      vehicle: v,
                                      onTap: () => _openDetail(v),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 26,
                    right: 20,
                    child: _Fab(onTap: _openAddVehicle),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _emptyState() {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Henüz araç eklenmedi',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
                const SizedBox(height: 6),
                const Text(
                  'Sağ alttaki + butonuna dokunarak ilk aracını ekleyebilirsin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Fab extends StatelessWidget {
  final VoidCallback onTap;
  const _Fab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: AppColors.orangeDim.withOpacity(0.5),
                blurRadius: 24,
                offset: const Offset(0, 10)),
          ],
        ),
        child: const Icon(Icons.add, color: Color(0xFF0E1512), size: 24),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AlertBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    final Vehicle v = data['vehicle'];
    final String nextStr = data['nextStr'];
    final int diff = data['diff'];
    final overdue = diff < 0;
    final color = overdue ? AppColors.redWarn : AppColors.orange;
    final glow = overdue ? const Color(0x24D9614F) : AppColors.orangeGlow;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: glow,
        border: Border.all(color: overdue ? AppColors.redWarn : AppColors.orangeDim),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(overdue ? Icons.warning_amber_rounded : Icons.notifications_active_outlined,
              color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12.5, color: AppColors.text, height: 1.4),
                children: [
                  TextSpan(
                      text: '${v.name} ',
                      style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                  TextSpan(text: '(${v.plate}) için muayene '),
                  if (overdue)
                    TextSpan(
                        text: 'süresi ${diff.abs()} gün geçti',
                        style: TextStyle(fontWeight: FontWeight.w700, color: color))
                  else
                    TextSpan(
                        text: 'tarihine ${diff == 0 ? "bugün" : "$diff gün"} kaldı'),
                  TextSpan(text: ' — $nextStr'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  const _VehicleCard({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    final nextInspection = calcNextInspection(v.lastInspectionDate, v.inspectionInterval);
    final diff = daysUntil(nextInspection);
    final overdue = diff != null && diff < 0;
    final statusText = v.history.isNotEmpty
        ? 'Son işlem yapılan kategori: ${v.history.first.cat}'
        : 'Henüz işlem kaydı yok';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgElev,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -16,
              top: -16,
              bottom: -16,
              width: 3,
              child: Container(color: AppColors.orange.withOpacity(0.7)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                          const SizedBox(height: 2),
                          Text(v.plate,
                              style: const TextStyle(
                                  fontFamily: monoFont, fontSize: 11, color: AppColors.textDim)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orangeGlow,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(v.type.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.orange)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.line),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fmtThousands(v.km),
                        style: const TextStyle(
                            fontFamily: monoFont, fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                    Text(v.unit, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                                color: AppColors.greenOk, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(statusText,
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ),
                        ],
                      ),
                    ),
                    if (nextInspection != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            overdue ? 'MUAYENE SÜRESİ GEÇTİ' : 'GELECEK MUAYENE',
                            style: TextStyle(
                                fontSize: 9.5,
                                color: overdue ? AppColors.redWarn : AppColors.textDim,
                                letterSpacing: 0.4),
                          ),
                          Text(
                            overdue ? '$nextInspection (${diff!.abs()} gün)' : nextInspection,
                            style: TextStyle(
                                fontFamily: monoFont,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: overdue ? AppColors.redWarn : AppColors.greenOk),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
