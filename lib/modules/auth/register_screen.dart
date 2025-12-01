import 'package:flutter/material.dart';

import 'auth_layout.dart';
import 'register_patient_screen.dart';
import 'register_pharmacist_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Pilih Jenis Akun',
      desc:
          'Daftar sebagai pasien untuk memantau terapi atau sebagai apoteker untuk membantu pasien.',
      marginTop: 60,
      showBackButton: true,
      onBack: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      ),
      formField: Column(
        children: [
          _RoleCard(
            icon: Icons.health_and_safety_rounded,
            title: 'Pasien',
            description:
                'Catat terapi, pantau pengingat obat, dan terhubung dengan komunitas.',
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterPatientScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _RoleCard(
            icon: Icons.local_pharmacy_rounded,
            title: 'Apoteker',
            description:
                'Dapatkan akses dashboard konsultan dan bantu pasien secara realtime.',
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RegisterPharmacistScreen(),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.black54, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
