import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:integrated_stroke/modules/auth/widget/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'global.dart';
import 'modules/auth/login_screen.dart';
import 'modules/dashboard/dashboard_screen.dart';
import 'services/local/auth_local_service.dart';
import 'services/notification_initializer.dart';
import 'styles/themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Global.init();
  await NotificationInitializer.initialize();

  await initializeDateFormatting('id_ID', null);

  final isLoggedIn = await AuthLocalService.isLoggedIn();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final Widget? homeOverride;
  const MyApp({super.key, required this.isLoggedIn, this.homeOverride});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Integrated Stroke',
      theme: AppTheme.data,
      debugShowCheckedModeBanner: false,
      home: homeOverride ?? const SplashScreen(),
    );
  }
}
