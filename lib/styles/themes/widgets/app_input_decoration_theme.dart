import 'package:flutter/material.dart';

import '../../colors/app_color.dart';

/// `AppInputDecorationTheme` adalah class utilitas untuk mengatur tema global komponen input (seperti `TextFormField`).
///
/// Tujuan utama dari class ini adalah menyediakan `InputDecorationTheme` yang konsisten di seluruh aplikasi.
/// Tema ini mengatur:
///
/// - Gaya teks untuk hint, helper, label, dan error menggunakan `AppFont`.
/// - Warna untuk border berdasarkan status (error, focused, enabled).
/// - Radius border melengkung (`15`) agar input terlihat modern dan konsisten.
/// - Warna transparan untuk latar belakang (`fillColor`) agar tidak menimpa desain dasar.
///
/// Diterapkan dalam `ThemeData.inputDecorationTheme` untuk memastikan seluruh form/input mengikuti gaya aplikasi.
class AppInputDecorationTheme {
  const AppInputDecorationTheme._();

  static InputDecorationTheme get data => InputDecorationTheme(
    errorMaxLines: 3,
    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
    hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
    helperStyle: TextStyle(fontSize: 14),
    errorStyle: TextStyle(fontSize: 12, color: AppColor.error),
    fillColor: Colors.transparent,
    labelStyle: TextStyle(fontSize: 16),
    filled: true,
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(width: 0.8, color: AppColor.error),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(width: 0.8, color: AppColor.error),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(width: 0.8, color: AppColor.outlined),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(width: 1, color: AppColor.text),
    ),
  );
}
