import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common_widgets.dart';

const List<String> vehicleTypes = [
  'Otomobil',
  'Motosiklet',
  'Kamyonet',
  'Kamyon',
  'Pikap',
  'Traktör',
  'Römork',
  'İş Makinesi',
  'Diğer',
];

/// Araçlarım sayfasındaki + butonuna basınca açılan sheet.
/// Kaydedilen aracı Navigator.pop ile geri döndürür; iptal edilirse null döner.
class AddVehicleSheet extends StatefulWidget {
  const AddVehicleSheet({super.key});

  @override
  State<AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends State<AddVehicleSheet> {
  final nameCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final plateCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final inspectionDateCtrl = TextEditingController();

  String? type;
  String unit = 'km';
  String? inspectionInterval;

  @override
  void dispose() {
    nameCtrl.dispose();
    yearCtrl.dispose();
    plateCtrl.dispose();
    valueCtrl.dispose();
    inspectionDateCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (nameCtrl.text.trim().isEmpty) return;

    final modelYear = int.tryParse(yearCtrl.text);
    final currentYear = DateTime.now().year;
    final age = (modelYear != null && modelYear > 1900 && modelYear <= currentYear)
        ? currentYear - modelYear
        : 0;

    final vehicle = Vehicle(
      id: const Uuid().v4(),
      name: nameCtrl.text.trim(),
      modelYear: modelYear,
      plate: plateCtrl.text.trim().isEmpty ? '—' : plateCtrl.text.trim(),
      type: type ?? 'Diğer',
      km: parseThousands(valueCtrl.text),
      unit: unit,
      inspectionInterval: inspectionInterval,
      lastInspectionDate:
          inspectionDateCtrl.text.isEmpty ? null : inspectionDateCtrl.text,
      age: age,
    );

    Navigator.pop(context, vehicle);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bgElev,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Yeni Araç Ekle',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.orange, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.bgElev2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                          side: const BorderSide(color: AppColors.line),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FieldLabel('Araç Adı'),
                              AppTextField(
                                controller: nameCtrl,
                                placeholder: 'Örn. Ford Courier',
                                inputFormatters: [TitleCaseInputFormatter()],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FieldLabel('Model Yılı'),
                              AppTextField(
                                controller: yearCtrl,
                                placeholder: '2022',
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FieldLabel('Plaka'),
                              AppTextField(
                                controller: plateCtrl,
                                placeholder: '37 K 0412',
                                inputFormatters: [UppercaseInputFormatter()],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FieldLabel('Araç Tipi'),
                              CustomDropdownField(
                                value: type,
                                options: vehicleTypes,
                                onChanged: (v) => setState(() => type = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FieldLabel('Güncel Km / Saat'),
                              AppTextField(
                                controller: valueCtrl,
                                placeholder: '0',
                                keyboardType: TextInputType.number,
                                inputFormatters: [ThousandsInputFormatter()],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FieldLabel('Birim'),
                              SegmentedToggle(
                                options: const ['km', 'saat'],
                                selected: unit,
                                onChanged: (v) => setState(() => unit = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FieldLabel('Periyodik Muayene Tekrarı'),
                              SegmentedToggle(
                                options: const ['1 Yıl', '2 Yıl', '3 Yıl'],
                                selected: inspectionInterval,
                                onChanged: (v) =>
                                    setState(() => inspectionInterval = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FieldLabel('Son Muayene Tarihi'),
                              AppTextField(
                                controller: inspectionDateCtrl,
                                placeholder: 'GG/AA/YYYY',
                                keyboardType: TextInputType.number,
                                inputFormatters: [DateSlashInputFormatter()],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(label: 'Aracı Kaydet', onPressed: _save),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
