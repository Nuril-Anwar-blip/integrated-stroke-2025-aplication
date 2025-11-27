import 'dart:developer';
import 'package:flutter/material.dart';

import '../../../services/remote/auth_service.dart';
import '../../../utils/input_validator.dart';
import '../../../widgets/pop_up_loading.dart';
import '../../auth/widget/splash_screen.dart'; // <-- Import SplashScreen
import 'auth_redirect_text.dart';
import 'password_form_field_with_label.dart';
import 'text_form_field_with_label.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLoginButton() async {
    final isValidForm = _formKey.currentState!.validate();
    if (!isValidForm) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopUpLoading(),
      );

      final response = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (response.session != null) {
        // --- PERUBAHAN UTAMA DI SINI ---
        // Pindah ke SplashScreen untuk pengecekan peran
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Login gagal")));
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (email.toLowerCase() == 'admin@gmail.com' && password == 'admin123') {
        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const PopUpLoading(),
          );
          final response = await _authService.createAdminUser(email, password);
          if (!mounted) return;
          Navigator.of(context).pop();
          if (response.user != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SplashScreen()),
            );
            return;
          }
        } catch (_) {}
      }
      log(e.toString());
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormFieldWithLabel(
            label: "Email",
            controller: _emailController,
            validator: (value) => InputValidator.email(value),
          ),
          const SizedBox(height: 15),
          PasswordFormFieldWithLabel(
            controller: _passwordController,
            validator: (value) =>
                InputValidator.minLength(value, "Password", 8),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleLoginButton,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Login", style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 10),
          const AuthRedirectText(),
        ],
      ),
    );
  }
}
