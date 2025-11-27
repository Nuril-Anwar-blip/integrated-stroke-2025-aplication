import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Class `Global` berfungsi sebagai pusat inisialisasi (service locator)
/// untuk berbagai layanan yang digunakan di aplikasi.
///
/// Dengan adanya `Global`, semua service penting seperti:
/// - Supabase (backend utama)
/// - Local Storage / Secure Storage
/// - Database lokal (contoh: chatDb, chatListDb)
/// - atau service lain (misal: API client, analytics, dll)
///
/// dapat diinisialisasi hanya sekali, lalu diakses secara global
/// lewat property static.
///
/// Pemanggilan dilakukan sekali saja saat aplikasi dijalankan pertama kali,
/// di dalam `main()`:
class Global {
  static Future init() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
    );
  }
}
