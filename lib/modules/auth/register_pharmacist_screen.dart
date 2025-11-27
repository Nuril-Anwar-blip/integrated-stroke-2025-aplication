import 'package:flutter/material.dart';

import 'auth_layout.dart';
import 'widget/register_form.dart';

class RegisterPharmacistScreen extends StatelessWidget {
  const RegisterPharmacistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Daftar Apoteker',
      desc:
          'Validasi data profesional Anda untuk membantu pasien secara daring.',
      formField: const RegisterForm(role: RegisterRole.pharmacist),
      marginTop: 60,
    );
  }
}
