import 'package:flutter/material.dart';

import '../../../styles/colors/app_color.dart';
import '../../../utils/util.dart';

class MultiSelectForm extends StatefulWidget {
  final String title;
  final String hintText;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;

  const MultiSelectForm({
    super.key,
    required this.title,
    required this.hintText,
    required this.selectedItems,
    required this.onChanged,
  });

  @override
  State<MultiSelectForm> createState() => _MultiSelectFormState();
}

class _MultiSelectFormState extends State<MultiSelectForm> {
  final List<String> _items = [];

  void _toggleItem(String item) {
    final itemLower = item.trim().toLowerCase();
    final updated = List<String>.from(widget.selectedItems);
    if (updated.contains(itemLower)) {
      updated.remove(itemLower);
    } else {
      updated.add(itemLower);
    }
    widget.onChanged(updated);
  }

  void _addCustomItem(String item) {
    final itemLower = item.trim().toLowerCase();
    setState(() {
      _items.add(itemLower);
    });
    final updated = List<String>.from(widget.selectedItems)..add(itemLower);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          "Tambahkan ${widget.title.toLowerCase()} Anda",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 5),

        // daftar item yang ditambahkan user
        ..._items.map((item) {
          final isSelected = selected.contains(item);
          return CheckboxListTile(
            value: isSelected,
            onChanged: (_) => _toggleItem(item),
            title: Text(capitalizeWords(item)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColor.primary,
            dense: true,
          );
        }),

        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.add, size: 20, color: AppColor.primary),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _showAddDialog(),
              child: Text(
                "Tambah ${widget.title.toLowerCase()}",
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColor.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddDialog() {
    final TextEditingController tempController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColor.background,
          title: Text(
            "Tambahkan ${widget.title}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: TextFormField(
            controller: tempController,
            decoration: InputDecoration(hintText: widget.hintText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Batal",
                style: TextStyle(color: AppColor.error),
              ),
            ),
            TextButton(
              onPressed: () {
                final input = tempController.text.trim();
                if (input.isNotEmpty) {
                  _addCustomItem(input);
                  Navigator.pop(context);
                }
              },
              child: Text("Tambah", style: TextStyle(color: AppColor.primary)),
            ),
          ],
        );
      },
    );
  }
}
