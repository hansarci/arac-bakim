import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/formatters.dart';
import '../utils/maintenance_rules.dart';
import '../widgets/add_action_sheet.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;
  /// Detay ekranında veri değiştiğinde (işlem ekleme, muayene) hemen çağrılır;
  /// kayıt geri tuşunu beklemeden yapılsın diye.
  final VoidCallback? onChanged;
  const VehicleDetailScreen({super.key, required this.vehicle, this.onChanged});

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
    widget.onChanged?.call();
  }

  Future<void> _markInspectionDone() async {
    final todayStr = todayTrDate();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        decoration: const BoxDecoration(
          color: AppColors.bgElev,
          border: Border(top: BorderSide(color: AppColors.line)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Text(
              '${v.name} için bugün ($todayStr) muayene yaptırdığını onaylıyor musun?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.text, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
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
          ],
        ),
      ),
    );

    if (confirmed == true) {
      setState(() => v.lastInspectionDate = todayStr);
      widget.onChanged?.call();
    }
  }

  Future<void> _editDate({
    required String title,
    required String? current,
    required void Function(String) onSave,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DateSheet(title: title, initial: current),
    );
    if (result == null) return;
    setState(() => onSave(result));
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final nextInspection = calcNextInspection(v.lastInspectionDate, v.inspectionInterval);
    final alerts = getMaintenanceAlerts(v);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ---- Sabit üst kısım: geri, isim, plaka, istatistikler, tarih kartları ----
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
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DateCard(
                          label: 'MUAYENE',
                          date: nextInspection,
                          onTap: nextInspection == null ? null : _markInspectionDone,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DateCard(
                          label: 'TRAFİK',
                          date: v.trafficInsuranceDate,
                          onTap: () => _editDate(
                            title: 'Trafik Sigortası',
                            current: v.trafficInsuranceDate,
                            onSave: (d) => v.trafficInsuranceDate = d,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DateCard(
                          label: 'KASKO',
                          date: v.kaskoDate,
                          onTap: () => _editDate(
                            title: 'Kasko',
                            current: v.kaskoDate,
                            onSave: (d) => v.kaskoDate = d,
                          ),
                        ),
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

/// Muayene / Trafik / Kasko için tek bir kart. date: GG/AA/YYYY (bitiş tarihi).
class _DateCard extends StatelessWidget {
  final String label;
  final String? date;
  final VoidCallback? onTap;
  const _DateCard({required this.label, required this.date, this.onTap});

  @override
  Widget build(BuildContext context) {
    final int? d = daysUntil(date);
    final bool overdue = d != null && d < 0;
    final bool soon = d != null && d >= 0 && d <= 15;

    final Color accent = d == null
        ? AppColors.textMuted
        : overdue
            ? AppColors.redWarn
            : soon
                ? AppColors.orange
                : AppColors.greenOk;
    final Color bg = overdue
        ? const Color(0x24D9614F)
        : soon
            ? AppColors.orangeGlow
            : AppColors.bgElev;
    final Color border = overdue
        ? AppColors.redWarn
        : soon
            ? AppColors.orangeDim
            : AppColors.line;

    final String sub = d == null
        ? 'Tarih ekle'
        : d < 0
            ? '${d.abs()} gün geçti'
            : d == 0
                ? 'bugün'
                : '$d gün kaldı';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.3)),
            const SizedBox(height: 4),
            Text(
              d == null ? '+' : date!,
              style: TextStyle(
                  fontFamily: monoFont,
                  fontSize: d == null ? 16 : 12,
                  fontWeight: FontWeight.w700,
                  color: accent),
            ),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 10, color: accent)),
          ],
        ),
      ),
    );
  }
}

/// Tarih girme / yenileme alt penceresi. Kaydedilen GG/AA/YYYY metnini döndürür.
class _DateSheet extends StatefulWidget {
  final String title;
  final String? initial;
  const _DateSheet({required this.title, required this.initial});

  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial ?? '');
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _isValid(String s) {
    final d = parseTrDate(s);
    return d != null && d.year >= 2000 && formatTrDate(d) == s;
  }

  void _save() {
    final text = _ctrl.text.trim();
    if (!_isValid(text)) {
      setState(() => _error = 'Geçerli bir tarih gir (örn. 15/03/2027)');
      return;
    }
    Navigator.pop(context, text);
  }

  /// Yenilendi: bitiş tarihi gelecekteyse ondan, geçmişse bugünden bir yıl sonrası.
  void _extend() {
    final old = parseTrDate(widget.initial);
    if (old == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final base = old.isAfter(today) ? old : today;
    Navigator.pop(context, formatTrDate(DateTime(base.year + 1, base.month, base.day)));
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = parseTrDate(widget.initial) != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
        decoration: const BoxDecoration(
          color: AppColors.bgElev,
          border: Border(top: BorderSide(color: AppColors.line)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 4),
            const Text('Bitiş tarihini GG/AA/YYYY olarak gir',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [_DateInputFormatter()],
              style: const TextStyle(
                  fontFamily: monoFont, fontSize: 16, color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'GG/AA/YYYY',
                hintStyle: const TextStyle(color: AppColors.textDim),
                filled: true,
                fillColor: AppColors.bg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.orange),
                ),
              ),
            ),
            SizedBox(
              height: 26,
              child: _error == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(_error!,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.redWarn)),
                    ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: const Color(0xFF14201A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            if (hasDate) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _extend,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.orangeDim),
                    foregroundColor: AppColors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Yenilendi: bir yıl uzat',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Yazarken GG/AA/YYYY biçimini otomatik kurar (sadece rakam yazman yeter).
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final capped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 2 || i == 4) buf.write('/');
      buf.write(capped[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
