import 'package:flutter/material.dart';
import '../../colors/app_color.dart';

class AppOutlinedButtonTheme {
  const AppOutlinedButtonTheme._();

  /// Theme global untuk OutlinedButton
  static OutlinedButtonThemeData get data => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      splashFactory: InkRipple.splashFactory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      backgroundColor: AppColor.background, // warna background
      foregroundColor: AppColor.text, // warna teks & icon
      side: BorderSide(color: AppColor.outlined), // warna outline
    ),
  );
}
