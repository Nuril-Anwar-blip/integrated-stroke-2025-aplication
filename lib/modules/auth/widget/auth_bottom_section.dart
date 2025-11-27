import 'package:flutter/material.dart';

class AuthBottomSection extends StatefulWidget {
  const AuthBottomSection({super.key});

  @override
  State<AuthBottomSection> createState() => _AuthBottomSectionState();
}

class _AuthBottomSectionState extends State<AuthBottomSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          spacing: 5,
          children: [
            Expanded(child: Divider()),
            Text(
              "atau",
              style: TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
            Expanded(child: Divider()),
          ],
        ),
        SizedBox(height: 20),
        OutlinedButton(
          onPressed: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              Image.asset("assets/images/ic_google.png", height: 20),
              Text("Login dengan Google"),
            ],
          ),
        ),
      ],
    );
  }
}
