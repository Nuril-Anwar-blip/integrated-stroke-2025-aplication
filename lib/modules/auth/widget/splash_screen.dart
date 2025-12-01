import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../pharmacist/dashboard/apoteker_dashboard_screen.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../admin/admin_dashboard_screen.dart';
import '../login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Beri sedikit jeda agar tidak terlalu cepat
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      // Jika tidak ada sesi, arahkan ke Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    try {
      // Ambil data profil, kh ususnya kolom 'role'
      final response = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', session.user.id)
          .maybeSingle();

      final role = response == null ? null : response['role'] as String?;

      if (!mounted) return;

      if (role == 'apoteker') {
        // Jika apoteker, arahkan ke Dashboard Apoteker
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ApotekerDashboardScreen()),
        );
      } else if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        // Jika bukan (pasien atau lainnya), arahkan ke Dashboard Pasien
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      // Jika gagal mengambil profil (misal, profil belum dibuat/RLS), arahkan ke Dashboard default
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
