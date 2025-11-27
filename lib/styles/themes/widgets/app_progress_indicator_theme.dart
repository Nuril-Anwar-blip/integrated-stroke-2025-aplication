import 'package:flutter/material.dart';

import '../../colors/app_color.dart';

/// `AppProgressIndicatorTheme` adalah class utilitas yang digunakan untuk mengatur tema global
/// dari widget indikator progres di seluruh aplikasi.
///
/// Class ini menghasilkan objek `ProgressIndicatorThemeData` yang menentukan:
///
/// - `color`: Warna utama indikator progres.
/// - `linearTrackColor`: Warna track (jalur) untuk `LinearProgressIndicator`.
/// - `strokeWidth`: Ketebalan garis untuk `CircularProgressIndicator`.
/// - `trackGap`: Jarak antara garis dan track pada indikator.
/// - `refreshBackgroundColor`: Warna latar belakang saat melakukan pull-to-refresh.
/// - `circularTrackPadding`: Padding di sekitar track indikator lingkaran.
/// - `circularTrackColor`: Warna track indikator lingkaran (diset transparan agar tak terlihat).
///
/// Tema ini diterapkan melalui `ThemeData.progressIndicatorTheme`
/// untuk menjaga konsistensi visual loading indicator.
class AppProgressIndicatorTheme {
  const AppProgressIndicatorTheme._();

  /// Getter statis agar bisa langsung dipanggil seperti objek.
  static ProgressIndicatorThemeData get data => ProgressIndicatorThemeData(
    color: AppColor.primary,
    linearTrackColor: AppColor.primary,
    strokeWidth: 1,
    trackGap: 2,
    refreshBackgroundColor: AppColor.background,
    circularTrackPadding: const EdgeInsets.all(10),
    circularTrackColor: Colors.transparent,
  );
}
