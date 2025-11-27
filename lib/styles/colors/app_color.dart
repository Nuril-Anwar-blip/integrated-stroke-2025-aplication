import 'package:flutter/material.dart';

/// Kelas utilitas `AppColor` menyediakan akses yang konsisten dan terstruktur
///
/// Tujuannya adalah untuk mempermudah pemanggilan warna tematik
/// berdasarkan kategori seperti:
/// - Primary, Secondary, Tertiary
/// - Background & Surface
/// - Text, Input, Error, Border, Shimmer, dsb.
///
/// Contoh penggunaan:
/// ```dart
/// final primary = AppColor.primary;
/// ```
///
/// Class ini bersifat statis dan tidak dapat diinstansiasi.
class AppColor {
  const AppColor._();

  static const MaterialColor primary = Colors.blue;
  static const Color onPrimary = Colors.white;

  static const Color background = Colors.white;
  static const Color text = Colors.black;
  static const Color outlined = Colors.blueGrey;
  static const Color error = Colors.redAccent;
}
