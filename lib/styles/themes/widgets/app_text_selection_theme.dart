import 'package:flutter/material.dart';

import '../../colors/app_color.dart';

/// `AppTextSelectionTheme` adalah class utilitas yang menyediakan konfigurasi
/// tema untuk elemen pemilihan teks (`TextSelection`) dalam aplikasi.
///
/// Class ini menghasilkan objek `TextSelectionThemeData` yang menentukan:
///
/// - `cursorColor`: Warna kursor teks saat mengetik.
/// - `selectionColor`: Warna area teks yang diseleksi (dengan opasitas 50%).
/// - `selectionHandleColor`: Warna gagang seleksi (drag handle).
///
/// Tema ini membantu menyelaraskan pengalaman input teks dengan gaya warna
/// keseluruhan dari aplikasi berdasarkan skema warna aktif.
///
/// Tema ini digunakan melalui `ThemeData.textSelectionTheme`.
class AppTextSelectionTheme {
  const AppTextSelectionTheme._();

  static TextSelectionThemeData get data => TextSelectionThemeData(
    cursorColor: AppColor.text,
    selectionColor: AppColor.primary.withValues(alpha: 0.5),
    selectionHandleColor: AppColor.primary,
  );
}
