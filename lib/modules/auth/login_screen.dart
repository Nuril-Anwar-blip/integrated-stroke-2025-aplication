import 'package:flutter/material.dart';
import 'package:integrated_stroke/modules/auth/widget/login_form.dart';

import 'auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return const AuthLayout(
      title: "Login",
      desc: "Masukkan email dan password Anda!",
      formField: LoginForm(),
      marginTop: 120,
    );
  }
}
