import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Küçük etiket + kutu birleşimi (Araç Adı, Plaka vb. alanların üstündeki başlık)
class FieldLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const FieldLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.4,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// km/saat, 1-2-3 yıl gibi az sayıda sabit seçenek arasında geçiş — tek seçimli
class SegmentedToggle extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onChanged;
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgElev2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.map((opt) {
          final active = opt == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? AppColors.orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: active ? const Color(0xFF14201A) : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Dokununca aşağı açılan basit dropdown (Araç Tipi için)
class CustomDropdownField extends StatelessWidget {
  final String? value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String placeholder;
  const CustomDropdownField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder = 'Seçiniz',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: AppColors.bgElev2,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options
                  .map((o) => ListTile(
                        title: Text(o,
                            style: TextStyle(
                              color: o == value ? AppColors.orange : AppColors.text,
                              fontWeight: o == value ? FontWeight.w700 : FontWeight.w400,
                            )),
                        onTap: () => Navigator.pop(ctx, o),
                      ))
                  .toList(),
            ),
          ),
        );
        if (result != null) onChanged(result);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgElev2,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? placeholder,
              style: TextStyle(
                fontSize: 14,
                color: value != null ? AppColors.text : AppColors.textDim,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Birden fazla seçilebilir kategori etiketleri (Motor, Fren Sistemi vb.)
class ChipMultiSelect extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  const ChipMultiSelect({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final active = selected.contains(opt);
        return GestureDetector(
          onTap: () => onToggle(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.orangeGlow : AppColors.bgElev2,
              border: Border.all(color: active ? AppColors.orangeDim : AppColors.line),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              opt,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.orange : AppColors.textMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Standart metin girişi kutusu (app genelinde aynı görünüm)
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? placeholder;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    required this.controller,
    this.placeholder,
    this.keyboardType,
    this.inputFormatters,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      style: const TextStyle(fontSize: 14, color: AppColors.text),
      cursorColor: AppColors.orange,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(color: AppColors.textDim),
        filled: true,
        fillColor: AppColors.bgElev2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orangeDim),
        ),
      ),
    );
  }
}

/// Turuncu dolgulu ana aksiyon butonu (Aracı Kaydet, İşlemi Kaydet vb.)
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const PrimaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: const Color(0xFF14201A),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
