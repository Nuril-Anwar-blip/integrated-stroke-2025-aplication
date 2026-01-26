import 'package:flutter/material.dart';

import '../colors/app_color.dart';
import 'widgets/app_app_bar_theme.dart';
import 'widgets/app_elevated_button_theme.dart';
import 'widgets/app_input_decoration_theme.dart';
import 'widgets/app_outlined_button_theme.dart';
import 'widgets/app_progress_indicator_theme.dart';
import 'widgets/app_text_selection_theme.dart';

/// Class `AppTheme` digunakan untuk membentuk `ThemeData` secara menyeluruh
/// berdasarkan `ThemeColor` dan `ThemeFont` yang diberikan.
///
/// Class ini membantu mengatur seluruh elemen visual aplikasi seperti:
/// - Warna dasar (`primaryColor`, `cardColor`, `scaffoldBackgroundColor`, dll)
/// - Komponen tema: AppBar, Button, Input, Text, dsb.
/// - Integrasi dengan `ColorScheme` dan `TextTheme` berbasis `ThemeFont`
///
/// Tujuan utama penggunaan class ini:
/// - Konsistensi styling antar halaman.
/// - Modularisasi dan pemisahan tanggung jawab antar bagian (color, font, widget theme).
class AppTheme {
  const AppTheme._();

  static ThemeData get data => ThemeData(
    primarySwatch: AppColor.primary,
    scaffoldBackgroundColor: AppColor.background,
    brightness: Brightness.light,
    appBarTheme: AppAppBarTheme.data,
    elevatedButtonTheme: AppElevatedButtonTheme.data,
    outlinedButtonTheme: AppOutlinedButtonTheme.data,
    progressIndicatorTheme: AppProgressIndicatorTheme.data,
    textSelectionTheme: AppTextSelectionTheme.data,
    inputDecorationTheme: AppInputDecorationTheme.data,
    splashFactory: InkRipple.splashFactory,
    dialogTheme: DialogThemeData(backgroundColor: AppColor.text),
  );

  static ThemeData get darkData => ThemeData(
    primarySwatch: AppColor.primary,
    scaffoldBackgroundColor: Colors.grey[900],
    brightness: Brightness.dark,
    appBarTheme: AppAppBarTheme.darkData,
    elevatedButtonTheme: AppElevatedButtonTheme.data,
    outlinedButtonTheme: AppOutlinedButtonTheme.data,
    progressIndicatorTheme: AppProgressIndicatorTheme.data,
    textSelectionTheme: AppTextSelectionTheme.data,
    inputDecorationTheme: AppInputDecorationTheme.darkData,
    splashFactory: InkRipple.splashFactory,
    dialogTheme: DialogThemeData(backgroundColor: Colors.grey[800]),
    cardColor: Colors.grey[800],
    dividerColor: Colors.grey[700],
  );
}
