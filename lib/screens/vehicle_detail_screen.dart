import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/formatters.dart';
import '../utils/maintenance_rules.dart';
import '../widgets/add_action_sheet.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;
  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  Vehicle get v => widget.vehicle;

  Future<void> _openAddAction() async {
    final result = await Navigator.push<ActionResult>(
      context,
      MaterialPageRoute(builder: (_) => AddActionSheet(vehicle: v)),
    );
    if (result == null) return;

    setState(() {
      v.history.insert(0, result.item);
      updateMaintenanceRecords(v, result.tags, result.kmNum);
      if (result.kmNum != null && result.kmNum! > v.km) {
        v.km = result.kmNum!;
      }
    });
  }

  Future<void> _markInspectionDone() async {
    final todayStr = todayTrDate();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElev,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.line),
        ),
        content: Text(
          '${v.name} için bugün ($todayStr) muayene yaptırdığını onaylıyor musun?',
          style: const TextStyle(color: AppColors.text, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.line),
                foregroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Vazgeç'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: const Color(0xFF14201A),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Onayla', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => v.lastInspectionDate = todayStr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextInspection = calcNextInspection(v.lastInspectionDate, v.inspectionInterval);
    final diff = daysUntil(nextInspection);
    final overdue = diff != null && diff < 0;
    final alerts = getMaintenanceAlerts(v);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ---- Sabit üst kısım: geri, isim, plaka, muayene, istatistikler ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back, size: 16, color: AppColors.textMuted),
                        SizedBox(width: 10),
                        Text('Araçlarım', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.line)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.name,
                                  style: const TextStyle(
                                      fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text)),
                              const SizedBox(height: 3),
                              Text('${v.plate} · ${v.type}',
                                  style: const TextStyle(
                                      fontFamily: monoFont, fontSize: 13, color: AppColors.orange)),
                            ],
                          ),
                          if (nextInspection != null)
                            GestureDetector(
                              onTap: _markInspectionDone,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    overdue ? 'Muayene Süresi Geçti' : 'Gelecek Muayene',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: overdue ? AppColors.redWarn : AppColors.textMuted,
                                        letterSpacing: 0.4),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    overdue ? '$nextInspection (${diff!.abs()} gün)' : nextInspection,
                                    style: TextStyle(
                                        fontFamily: monoFont,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: overdue ? AppColors.redWarn : AppColors.greenOk),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                              child: _StatCell(
                                  value: fmtThousands(v.km), label: 'işlem yapılan ${v.unit}')),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _StatCell(
                                  value: '${v.history.length}', label: 'kayıtlı işlem')),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCell(value: '${v.age}', label: 'yıl yaşında')),
                        ],
                      ),
                    ],
                  ),
                ),
                if (alerts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      children: [for (final a in alerts) _MaintenanceAlertCard(alert: a)],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      Text('BAKIM GEÇMİŞİ',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.6)),
                    ],
                  ),
                ),
                // ---- Sadece bu liste kayar ----
                Expanded(
                  child: v.history.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Text('Henüz işlem kaydı yok',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: v.history.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => _HistoryTile(item: v.history[i], unit: v.unit),
                        ),
                ),
              ],
            ),
            Positioned(
              bottom: 26,
              right: 20,
              child: GestureDetector(
                onTap: _openAddAction,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.bgElev2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontFamily: monoFont, fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _MaintenanceAlertCard extends StatelessWidget {
  final MaintenanceAlert alert;
  const _MaintenanceAlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final overdue = alert.type == MaintenanceAlertType.overdue;
    final color = overdue ? AppColors.redWarn : AppColors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: overdue ? const Color(0x24D9614F) : AppColors.orangeGlow,
        border: Border.all(color: overdue ? AppColors.redWarn : AppColors.orangeDim),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(overdue ? Icons.warning_amber_rounded : Icons.access_time, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                children: [
                  TextSpan(
                    text: overdue ? '${fmtThousands(alert.amount)} km ' : '~${fmtThousands(alert.amount)} km ',
                    style: TextStyle(fontFamily: monoFont, fontWeight: FontWeight.w700, color: color),
                  ),
                  TextSpan(
                    text: overdue
                        ? '${alert.label} gecikti'
                        : '${alert.label.substring(0, 1).toLowerCase()}${alert.label.substring(1)} bekleniyor — geçmiş kayıtlara göre tahmin',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryItem item;
  final String unit;
  const _HistoryTile({required this.item, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.bgElev,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.cat,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.greenOk)),
                const SizedBox(height: 2),
                Text(item.sub, style: const TextStyle(fontSize: 11.5, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.km > 0 ? '${fmtThousands(item.km)} $unit' : '—',
                style: const TextStyle(fontFamily: monoFont, fontSize: 13, color: AppColors.text),
              ),
              const SizedBox(height: 2),
              Text(item.date, style: const TextStyle(fontSize: 10.5, color: AppColors.textDim)),
            ],
          ),
        ],
      ),
    );
  }
}
