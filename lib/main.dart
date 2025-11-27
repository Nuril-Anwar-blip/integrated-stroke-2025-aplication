import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:integrated_strokes2025/modules/auth/widget/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import untuk inisialisasi locale

import 'global.dart';
import 'modules/auth/login_screen.dart';
import 'modules/dashboard/dashboard_screen.dart';
import 'services/local/auth_local_service.dart';
import 'styles/themes/app_theme.dart';

Future<void> main() async {
  // Blok inisialisasi aplikasi
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Global.init();

  // Inisialisasi locale bahasa Indonesia untuk format tanggal
  await initializeDateFormatting('id_ID', null);

  // Cek status login pengguna
  final isLoggedIn = await AuthLocalService.isLoggedIn();

  // Menjalankan aplikasi
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Integrated Stroke',
      theme: AppTheme.data,
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug
      home: const SplashScreen(),
    );
  }
}
