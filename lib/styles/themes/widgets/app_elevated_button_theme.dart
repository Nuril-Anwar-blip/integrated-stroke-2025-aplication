import 'package:flutter/material.dart';

import '../../colors/app_color.dart';

/// `AppElevatedButtonTheme` adalah class helper untuk mengatur tema global tombol `ElevatedButton`.
///
/// Fungsi utamanya adalah menyediakan instance `ElevatedButtonThemeData` yang:
/// - Menggunakan `InkRipple` sebagai efek splash.
/// - Menerapkan `borderRadius` membulat.
/// - Menyediakan padding horizontal dan vertikal secara konsisten.
/// - Menetapkan elevasi tombol ringan agar tidak terlihat terlalu menonjol.
///
/// Dapat digunakan dalam `ThemeData.elevatedButtonTheme` untuk menjaga konsistensi tombol di seluruh aplikasi.
class AppElevatedButtonTheme {
  const AppElevatedButtonTheme._();

  static ElevatedButtonThemeData get data => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      splashFactory: InkRipple.splashFactory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      foregroundColor: AppColor.onPrimary,
      elevation: 0,
      textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      backgroundColor: AppColor.primary,
    ),
  );
}
