import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/vehicle_list_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  runApp(const AracBakimApp());
}

class AracBakimApp extends StatelessWidget {
  const AracBakimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Araç Bakım',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const VehicleListScreen(),
    );
  }
}
