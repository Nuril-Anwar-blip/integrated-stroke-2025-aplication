import 'package:flutter/material.dart';

import 'auth_layout.dart';
import 'widget/register_form.dart';

class RegisterPatientScreen extends StatelessWidget {
  const RegisterPatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Daftar Pasien',
      desc: 'Isi data diri lengkap untuk memulai perjalanan pemulihan Anda.',
      formField: const RegisterForm(role: RegisterRole.patient),
      marginTop: 60,
    );
  }
}
