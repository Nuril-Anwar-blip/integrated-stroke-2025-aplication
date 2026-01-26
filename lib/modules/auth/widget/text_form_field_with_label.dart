import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Jenis inputan untuk TextFormField
enum InputFieldType { number, text }

class TextFormFieldWithLabel extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String? value)? validator;
  final InputFieldType fieldType;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final bool compact;

  const TextFormFieldWithLabel({
    super.key,
    required this.label,
    required this.controller,
    required this.validator,
    this.fieldType = InputFieldType.text,
    this.hintText,
    this.inputFormatters,
    this.compact = false,
  });

  TextInputType _getKeyboardType() {
    switch (fieldType) {
      case InputFieldType.number:
        return TextInputType.number;
      case InputFieldType.text:
      default:
        return TextInputType.text;
    }
  }

  /**
   * Formater default berdasarkan tipe input
   * number: hanya digit
   * text: default
   */
  List<TextInputFormatter> _getDefaultFormatter() {
    switch (fieldType) {
      case InputFieldType.number:
        return [FilteringTextInputFormatter.digitsOnly];
      case InputFieldType.text:
        // hanya untuk dan spasi
        return [FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9@-_.\s]"))];
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: compact ? 13 : 16,
      fontWeight: FontWeight.w600,
    );

    final contentPadding = EdgeInsets.symmetric(
      horizontal: compact ? 12 : 14,
      vertical: compact ? 10 : 14,
    );

    // gabungkan formatter default + formatter tambahan dari luar
    final formatters = <TextInputFormatter>[
      ..._getDefaultFormatter(),
      ...(inputFormatters ?? []),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 3),
          child: Text(label, style: labelStyle),
        ),
        const SizedBox(height: 6),

        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: _getKeyboardType(),
          inputFormatters: formatters,
          decoration: InputDecoration(
            isDense: compact,
            contentPadding: contentPadding,
            hintText: hintText ?? "Masukkan ${label.toLowerCase()}",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       spacing: 5,
//       children: [
//         Padding(
//           padding: EdgeInsets.only(left: 3),
//           child: Text(
//             label,
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//           ),
//         ),
//         TextFormField(
//           validator: validator,
//           controller: controller,
//           keyboardType: keyboardType,
//           inputFormatters: inputFormatters,
//           decoration: InputDecoration(
//             hintText: hintText ?? "Masukkan ${label.toLowerCase()}",
//           ),
//         ),
//       ],
//     );
//   }
// }
