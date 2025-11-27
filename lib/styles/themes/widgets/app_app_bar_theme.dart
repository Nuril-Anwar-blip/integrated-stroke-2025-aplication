import 'package:flutter/material.dart';

import '../../colors/app_color.dart';

/// Class `AppAppBarTheme` menyediakan konfigurasi tema khusus untuk komponen `AppBar`.
///
/// Fungsi utamanya adalah mengatur:
/// - `backgroundColor`: menggunakan warna `background` dari AppColor.
/// - `scrolledUnderElevation`: diset ke 0 agar tidak ada bayangan saat scroll.
/// - `elevation`: diset ke 0 untuk tampilan flat tanpa bayangan.
///
/// Tujuan dari class ini adalah menjaga tampilan `AppBar` tetap konsisten
/// dan terintegrasi dengan sistem tema aplikasi.
///
/// Cocok digunakan pada `ThemeData.appBarTheme` untuk menyatukan desain global.
class AppAppBarTheme {
  const AppAppBarTheme._();

  static AppBarTheme get data => AppBarTheme(
    backgroundColor: AppColor.background,
    scrolledUnderElevation: 0,
    elevation: 0,
  );
}
