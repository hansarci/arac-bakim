import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// PDF'e nelerin gireceğini seçtiren alt pencere.
class PdfOptions {
  final bool dates;
  final bool history;
  const PdfOptions({required this.dates, required this.history});
}

class PdfOptionsSheet extends StatefulWidget {
  const PdfOptionsSheet({super.key});

  @override
  State<PdfOptionsSheet> createState() => _PdfOptionsSheetState();
}

class _PdfOptionsSheetState extends State<PdfOptionsSheet> {
  bool _dates = true;
  bool _history = true;

  Widget _option(String text, bool value, ValueChanged<bool> onChanged) {
    return CheckboxListTile(
      value: value,
      onChanged: (b) => onChanged(b ?? false),
      activeColor: AppColors.orange,
      checkColor: const Color(0xFF14201A),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(text, style: const TextStyle(color: AppColors.text, fontSize: 14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Text('PDF Raporu',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 4),
          const Text('Rapora dahil et',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          _option('Muayene / Trafik / Kasko tarihleri', _dates,
              (b) => setState(() => _dates = b)),
          _option('Bakım geçmişi', _history, (b) => setState(() => _history = b)),
          const SizedBox(height: 14),
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
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    PdfOptions(dates: _dates, history: _history),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: const Color(0xFF14201A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('PDF Oluştur ve Paylaş',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
