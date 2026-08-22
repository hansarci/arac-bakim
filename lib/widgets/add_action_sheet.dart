import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/formatters.dart';
import 'common_widgets.dart';
import 'tag_input.dart';

const List<String> maintenanceCategories = [
  'Motor',
  'Yağ / Filtre',
  'Fren Sistemi',
  'Alt Takım / Rot',
  'Lastik / Jant',
  'Şanzıman',
  'Elektrik',
  'Kaporta',
  'Periyodik / Resmi',
  'Diğer',
];

/// Araç detay sayfasındaki + butonuna basınca açılan tam ekran sayfa.
/// Kaydedilen HistoryItem'ı ve girilen km'yi (varsa) Navigator.pop ile döndürür.
class AddActionSheet extends StatefulWidget {
  final Vehicle vehicle;
  const AddActionSheet({super.key, required this.vehicle});

  @override
  State<AddActionSheet> createState() => _AddActionSheetState();
}

class ActionResult {
  final HistoryItem item;
  final int? kmNum;
  final List<String> tags;
  ActionResult({required this.item, required this.kmNum, required this.tags});
}

class _AddActionSheetState extends State<AddActionSheet> {
  late final TextEditingController dateCtrl;
  final kmCtrl = TextEditingController();
  final tagController = TagInputController();
  final Set<String> selectedCats = {};
  final FocusNode dateFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    dateCtrl = TextEditingController(text: todayTrDate());
    dateFocusNode.addListener(_onDateFocusChange);
  }

  @override
  void dispose() {
    dateFocusNode.removeListener(_onDateFocusChange);
    dateFocusNode.dispose();
    dateCtrl.dispose();
    kmCtrl.dispose();
    tagController.dispose();
    super.dispose();
  }

  void _onDateFocusChange() {
    if (dateFocusNode.hasFocus) {
      dateCtrl.clear();
    } else if (dateCtrl.text.isEmpty) {
      dateCtrl.text = todayTrDate();
    }
  }

  void _save() {
    tagController.commitPending();
    if (tagController.tags.isEmpty) return;

    final kmNum = kmCtrl.text.isEmpty ? null : parseThousands(kmCtrl.text);
    final catLabel = selectedCats.isEmpty ? 'Diğer' : selectedCats.join(' / ');

    final item = HistoryItem(
      cat: catLabel,
      sub: tagController.joined,
      km: kmNum ?? 0,
      date: dateCtrl.text.isEmpty ? '—' : dateCtrl.text,
    );

    Navigator.pop(
      context,
      ActionResult(item: item, kmNum: kmNum, tags: List.of(tagController.tags)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kmLabel = widget.vehicle.unit == 'saat' ? 'İşlem Saati' : 'İşlem Km';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.orange),
        ),
        title: const Text('Yeni İşlem Ekle',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.line),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Tarih'),
                    AppTextField(
                      controller: dateCtrl,
                      focusNode: dateFocusNode,
                      placeholder: 'GG/AA/YYYY',
                      keyboardType: TextInputType.number,
                      inputFormatters: [DateSlashInputFormatter()],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FieldLabel(kmLabel),
                    AppTextField(
                      controller: kmCtrl,
                      placeholder: '0',
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsInputFormatter()],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const FieldLabel('Yapılan İşlem(ler)'),
          ChipTagInput(controller: tagController),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'KATEGORİ',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '(opsiyonel, birden fazla seçilebilir)',
                style: TextStyle(fontSize: 11.5, color: AppColors.textDim),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ChipMultiSelect(
            options: maintenanceCategories,
            selected: selectedCats,
            onToggle: (opt) => setState(() {
              if (selectedCats.contains(opt)) {
                selectedCats.remove(opt);
              } else {
                selectedCats.add(opt);
              }
            }),
          ),
          const SizedBox(height: 22),
          PrimaryButton(label: 'İşlemi Kaydet', onPressed: _save),
        ],
      ),
    );
  }
}
