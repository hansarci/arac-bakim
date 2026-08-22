import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Km/Saat alanlarına yazarken otomatik binlik nokta ekler (251.365 gibi)
class ThousandsInputFormatter extends TextInputFormatter {
  final _fmt = NumberFormat('#,###', 'tr_TR');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = _fmt.format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Rakam yazdıkça otomatik GG/AA/YYYY formatı uygular
class DateSlashInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);
    String formatted = digits;
    if (digits.length > 4) {
      formatted =
          '${digits.substring(0, 2)}/${digits.substring(2, 4)}/${digits.substring(4)}';
    } else if (digits.length > 2) {
      formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Plaka gibi alanlarda tüm harfleri büyük yazar
class UppercaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Araç Adı gibi alanlarda her sözcüğün ilk harfini büyük yazar
class TitleCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final buffer = StringBuffer();
    bool capitalizeNext = true;
    for (final ch in text.split('')) {
      if (capitalizeNext && ch.trim().isNotEmpty) {
        buffer.write(ch.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(ch);
      }
      if (ch == ' ') capitalizeNext = true;
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: newValue.selection,
    );
  }
}

/// Formatlı ("251.365") bir km stringini int'e çevirir
int parseThousands(String s) {
  final digits = s.replaceAll(RegExp(r'\D'), '');
  return digits.isEmpty ? 0 : int.parse(digits);
}

/// Bir int'i "251.365" gibi binlik noktalı gösterir
String fmtThousands(int n) => NumberFormat('#,###', 'tr_TR').format(n);
