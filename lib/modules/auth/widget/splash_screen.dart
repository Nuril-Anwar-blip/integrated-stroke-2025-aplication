import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../pharmacist/dashboard/apoteker_dashboard_screen.dart';
import '../../admin/admin_dashboard_screen.dart';
import '../../dashboard/dashboard_screen.dart'; // Halaman utama pasien (radial menu)
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
      final client = Supabase.instance.client;
      final userId = session.user.id;

      final userRow = await client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      String? role = userRow != null ? userRow['role'] as String? : null;

      if (role == null) {
        final adminRow = await client
            .from('admins')
            .select('user_id')
            .eq('user_id', userId)
            .maybeSingle();
        if (adminRow != null) role = 'admin';
      }

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else if (role == 'apoteker') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ApotekerDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
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
