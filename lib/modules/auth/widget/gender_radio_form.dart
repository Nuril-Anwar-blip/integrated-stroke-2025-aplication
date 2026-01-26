// import 'package:flutter/material.dart';

// import '../../../styles/colors/app_color.dart';

// class GenderForm extends StatefulWidget {
//   final String selectedGender;
//   final ValueChanged<String> onChanged;

//   const GenderForm({
//     super.key,
//     required this.selectedGender,
//     required this.onChanged,
//   });

//   @override
//   State<GenderForm> createState() => _GenderFormState();
// }

// class _GenderFormState extends State<GenderForm> {
//   late String _currentGender;

//   @override
//   void initState() {
//     super.initState();
//     _currentGender = widget.selectedGender;
//   }

//   void _onGenderChanged(String? value) {
//     if (value != null) {
//       setState(() {
//         _currentGender = value;
//       });
//       widget.onChanged(value);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "Jenis Kelamin",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 5),
//         Column(
//           children: [
//             RadioListTile<String>(
//               value: "male",
//               title: const Text("Pria"),
//               groupValue: _currentGender,
//               onChanged: _onGenderChanged,
//               activeColor: AppColor.primary,
//               dense: true,
//             ),
//             RadioListTile<String>(
//               value: "female",
//               title: const Text("Wanita"),
//               groupValue: _currentGender,
//               onChanged: _onGenderChanged,
//               activeColor: AppColor.primary,
//               dense: true,
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../../../styles/colors/app_color.dart';

class GenderForm extends StatefulWidget {
  final String selectedGender;
  final ValueChanged<String> onChanged;

  const GenderForm({
    super.key,
    required this.selectedGender,
    required this.onChanged,
  });

  @override
  State<GenderForm> createState() => _GenderFormState();
}

class _GenderFormState extends State<GenderForm> {
  late String _currentGender;

  @override
  void initState() {
    super.initState();
    _currentGender = widget.selectedGender;
  }

  void _onGenderChanged(String? value) {
    if (value == null) return;
    setState(() => _currentGender = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Jenis Kelamin",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),

        // ✅ Radio horizontal
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _onGenderChanged("male"),
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<String>(
                      value: "male",
                      groupValue: _currentGender,
                      onChanged: _onGenderChanged,
                      activeColor: AppColor.primary,
                    ),
                    const Text("Pria"),
                  ],
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => _onGenderChanged("female"),
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<String>(
                      value: "female",
                      groupValue: _currentGender,
                      onChanged: _onGenderChanged,
                      activeColor: AppColor.primary,
                    ),
                    const Text("Wanita"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
