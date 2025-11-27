import 'package:flutter/material.dart';

import '../../../styles/colors/app_color.dart';

class PasswordFormFieldWithLabel extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String? value)? validator;

  const PasswordFormFieldWithLabel({
    super.key,
    required this.controller,
    required this.validator,
  });

  @override
  State<PasswordFormFieldWithLabel> createState() =>
      _PasswordFormFieldWithLabelState();
}

class _PasswordFormFieldWithLabelState
    extends State<PasswordFormFieldWithLabel> {
  bool _obscureText = true; // default: password disembunyikan

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 5,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 3),
          child: Text(
            "Password",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _obscureText,
          decoration: InputDecoration(
            hintText: "Masukkan password",
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: AppColor.text,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
