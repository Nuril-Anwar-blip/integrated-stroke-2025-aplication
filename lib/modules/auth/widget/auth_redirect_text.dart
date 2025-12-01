import 'package:flutter/material.dart';

import '../register_screen.dart';
import '../login_screen.dart';

class AuthRedirectText extends StatelessWidget {
  final bool isLogin;

  const AuthRedirectText({super.key, this.isLogin = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLogin ? "Belum punya akun? " : "Sudah punya akun? ",
          style: const TextStyle(fontSize: 14),
        ),
        GestureDetector(
          onTap: isLogin
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => const RegisterScreen(),
                  ),
                )
              : () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  ),
          child: Text(
            isLogin ? "Register" : "Login",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}
