import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextFormFieldWithLabel extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String? value)? validator;
  final TextInputType? keyboardType;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;

  const TextFormFieldWithLabel({
    super.key,
    required this.label,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.hintText,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 5,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 3),
          child: Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        TextFormField(
          validator: validator,
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hintText ?? "Masukkan ${label.toLowerCase()}",
          ),
        ),
      ],
    );
  }
}
