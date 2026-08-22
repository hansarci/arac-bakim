import 'package:flutter/material.dart';

/// Kutur M3 / Orjanda ile aynı görsel dil: koyu yeşil-siyah zemin, turuncu vurgu,
/// sayılarda JetBrains Mono (font dosyası eklenmediği için sistemin monospace'i kullanılıyor;
/// istersen assets/fonts altına JetBrains Mono ttf ekleyip pubspec'e tanımlayabilirsin).
class AppColors {
  static const bg = Color(0xFF0E1512);
  static const bgElev = Color(0xFF161F1A);
  static const bgElev2 = Color(0xFF1D2822);
  static const line = Color(0xFF2A362F);
  static const text = Color(0xFFEAE7DE);
  static const textMuted = Color(0xFF8C9891);
  static const textDim = Color(0xFF5C6961);
  static const orange = Color(0xFFE8823C);
  static const orangeDim = Color(0xFFB5652F);
  static const orangeGlow = Color(0x24E8823C); // ~14% opacity
  static const greenOk = Color(0xFF6FAE7A);
  static const redWarn = Color(0xFFD9614F);
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bg,
  fontFamily: 'Inter',
  colorScheme: const ColorScheme.dark(
    primary: AppColors.orange,
    secondary: AppColors.orange,
    surface: AppColors.bgElev,
    background: AppColors.bg,
    error: AppColors.redWarn,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.bg,
    foregroundColor: AppColors.text,
    elevation: 0,
    centerTitle: false,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: AppColors.text),
  ),
);

const monoFont = 'monospace'; // JetBrains Mono eklenirse burada değiştir
