import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/emergency_contact_model.dart';
import '../../../models/user_model.dart';
import '../../../services/remote/auth_service.dart';
import '../../../utils/input_validator.dart';
import '../../../widgets/pop_up_loading.dart';
import '../../auth/widget/splash_screen.dart';
import 'auth_redirect_text.dart';
import 'gender_radio_form.dart';
import 'multi_select_form.dart';
import 'password_form_field_with_label.dart';
import 'text_form_field_with_label.dart';

// Role registrasi untuk menentukan apakah user pasien atau apoteker
enum RegisterRole { patient, pharmacist }

class RegisterForm extends StatefulWidget {
  // role default pasien
  final RegisterRole role;
  const RegisterForm({super.key, this.role = RegisterRole.patient});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  // Stepper State
  // menyimpan step yang aktif (1, 2, 3)
  int _currentStep = 0;

  // FormKey khusus step 1
  late final GlobalKey<FormState> _formKeyStep1;

  // FormKey khusus step 2
  late final GlobalKey<FormState> _formKeyStep2;

  // FormKey khusus step 3
  late final GlobalKey<FormState> _formKeyStep3;

  // late final GlobalKey<FormState> _formKey;
  // Text Controller
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _emergencyContactNameController;
  late final TextEditingController _emergencyContactRelationshipController;
  late final TextEditingController _emergencyContactPhoneNumberController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController
  _pharmacistCodeController; // <-- Controller untuk kode apoteker

  // AuthService
  // service untuk ke backend
  final _authService = AuthService();

  // List pilihan multi select
  List<String> _selectedMedicalHistory = [];
  List<String> _selectedDrugAllergy = [];
  // Gender
  String gender = "male";
  // helper untuk cek apakah role apoteker
  bool get _isPharmacist => widget.role == RegisterRole.pharmacist;

  @override
  void initState() {
    super.initState();
    // init form key
    _formKeyStep1 = GlobalKey<FormState>();
    _formKeyStep2 = GlobalKey<FormState>();
    _formKeyStep3 = GlobalKey<FormState>();

    // _formKey = GlobalKey<FormState>();
    // init controller
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _fullNameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _emergencyContactNameController = TextEditingController();
    _emergencyContactRelationshipController = TextEditingController();
    _emergencyContactPhoneNumberController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _pharmacistCodeController =
        TextEditingController(); // <-- Inisialisasi controller
  }

  @override
  void dispose() {
    // dispose controller untuk menghindari memory leak
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactRelationshipController.dispose();
    _emergencyContactPhoneNumberController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _pharmacistCodeController.dispose(); // <-- Jangan lupa dispose
    super.dispose();
  }

  /**
   * Validasi Step
   * 
   * fungsi ini memastikan user tidak bisa lanjut step
   * sebelum data pada step itu valid
   */

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      // step 1: Data Diri
      return _formKeyStep1.currentState?.validate() ?? false;
    }

    if (_currentStep == 1) {
      // step 2: Kesehatan
      // Apoteker tidak perlu mengisi data kesehatan
      if (_isPharmacist) return true;
      return _formKeyStep2.currentState?.validate() ?? false;
    }

    if (_currentStep == 2) {
      // step 3: Kontak darurat
      // Apoteker tidak perlu mengisi data kontak darurat
      if (_isPharmacist) return true;
      return _formKeyStep3.currentState?.validate() ?? false;
    }

    return false;
  }

  void _nextStep() async {
    final valid = _validateCurrentStep();
    if (!valid) return;

    // jika belum step terakhir, maju step
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      // step terakhir -> submit
      await _handleRegisterButton();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // submit register
  Future<void> _handleRegisterButton() async {
    try {
      // tampilan loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopUpLoading(),
      );

      // susun user model dari input
      final user = UserModel(
        email: _emailController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        fullName: _fullNameController.text.trim(),

        // jika apoteker, data kesehatan di-set 0/empty
        age: _isPharmacist ? 0 : int.tryParse(_ageController.text.trim()) ?? 0,
        height: _isPharmacist
            ? 0
            : double.tryParse(_heightController.text.trim()) ?? 0.0,
        weight: _isPharmacist
            ? 0
            : double.tryParse(_weightController.text.trim()) ?? 0.0,
        medicalHistory: _isPharmacist ? const [] : _selectedMedicalHistory,
        gender: gender,
        drugAllergy: _isPharmacist ? const [] : _selectedDrugAllergy,

        // jika apoteker, emergency contact default
        emergencyContact: _isPharmacist
            ? EmergencyContactModel(
                name: '-',
                relationship: '-',
                phoneNumber: '-',
              )
            : EmergencyContactModel(
                name: _emergencyContactNameController.text.trim(),
                relationship: _emergencyContactRelationshipController.text
                    .trim(),
                phoneNumber: _emergencyContactPhoneNumberController.text.trim(),
              ),
      );

      // panggil api register
      final response = await _authService.register(
        user: user,
        password: _passwordController.text.trim(),
        pharmacistCode: _isPharmacist
            ? _pharmacistCodeController.text.trim()
            : null,
      );

      // tutup loading
      if (!mounted) return;
      Navigator.of(context).pop();

      // jika sukses -> pindah ke splash screen
      if (response.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      } else {
        // gagal register
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Registrasi gagal")));
      }
    } catch (e) {
      // error -> tutup loading lalu tampilkan error
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // Data diri
  Widget _step1DataDiri() {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormFieldWithLabel(
            label: "Nama Lengkap",
            controller: _fullNameController,
            validator: (v) => InputValidator.emptyField(v, "Nama"),
          ),
          const SizedBox(height: 10),
          TextFormFieldWithLabel(
            label: "Nomor Telepon Anda",
            controller: _phoneNumberController,
            validator: (v) => InputValidator.emptyField(v, "Nama"),
          ),
          const SizedBox(height: 10),
          TextFormFieldWithLabel(
            label: "Email",
            controller: _emailController,
            validator: (v) => InputValidator.email(v),
          ),
          const SizedBox(height: 10),
          PasswordFormFieldWithLabel(
            controller: _passwordController,
            validator: (v) => InputValidator.minLength(v, "Password", 8),
          ),
          const SizedBox(height: 10),
          GenderForm(
            selectedGender: gender,
            onChanged: (value) => setState(() => gender = value),
          ),

          // Jika apoteker -> munculkan field kode registrasi apoteker
          if (_isPharmacist)
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: TextFormFieldWithLabel(
                label: "Kode Registrasi Apoteker",
                controller: _pharmacistCodeController,
                validator: (value) =>
                    InputValidator.emptyField(value, "Kode Registrasi"),
              ),
            ),
        ],
      ),
    );
  }

  // kesehatan
  Widget _step2KesehatanFisik() {
    if (_isPharmacist) {
      return const Text(
        "Role apoteker tidak membutuhkan data kesehatan & fisik.",
        style: TextStyle(fontSize: 14),
      );
    }

    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormFieldWithLabel(
            label: "Umur (Tahun)",
            controller: _ageController,
            validator: (v) => InputValidator.emptyField(v, "Umur"),
            fieldType: InputFieldType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextFormFieldWithLabel(
                  label: "Tinggi (cm)",
                  controller: _heightController,
                  validator: (v) =>
                      InputValidator.emptyField(v, "Tinggi badan"),
                  fieldType: InputFieldType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormFieldWithLabel(
                  label: "Berat (kg)",
                  controller: _weightController,
                  validator: (v) => InputValidator.emptyField(v, "Berat badan"),
                  fieldType: InputFieldType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          MultiSelectForm(
            title: "Riwayat Penyakit",
            hintText: "Masukkan penyakit",
            selectedItems: _selectedMedicalHistory,
            onChanged: (newList) =>
                setState(() => _selectedMedicalHistory = newList),
          ),
          const SizedBox(height: 10),
          MultiSelectForm(
            title: "Alergi Obat",
            hintText: "Masukkan obat",
            selectedItems: _selectedDrugAllergy,
            onChanged: (list) => setState(() => _selectedDrugAllergy = list),
          ),
        ],
      ),
    );
  }

  // kontak darurat
  Widget _step3KontakDarurat() {
    // Apoteker tidak butuh step ini
    if (_isPharmacist) {
      return const Text(
        "Role apoteker tidak membutuhkan kontak darurat.",
        style: TextStyle(fontSize: 14),
      );
    }

    return Form(
      key: _formKeyStep3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Kontak Darurat",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          TextFormFieldWithLabel(
            label: "Nama Kontak",
            controller: _emergencyContactNameController,
            validator: (v) => InputValidator.emptyField(v, "Nama kontak"),
          ),
          const SizedBox(height: 10),
          TextFormFieldWithLabel(
            label: "Hubungan",
            controller: _emergencyContactRelationshipController,
            validator: (v) => InputValidator.emptyField(v, "Hubungan"),
          ),
          const SizedBox(height: 10),
          TextFormFieldWithLabel(
            label: "Nomor Telepon Kontak",
            controller: _emergencyContactPhoneNumberController,
            validator: (v) => InputValidator.phoneNumber(v),
          ),
        ],
      ),
    );
  }

  // build ui
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stepper(
          // Ini Stepper vertikal
          type: StepperType.vertical,
          currentStep: _currentStep,

          // klik step untuk pindah
          onStepTapped: (step) => setState(() => _currentStep = step),

          // tombol Lanjut
          onStepContinue: _nextStep,

          // tombol Kembali
          onStepCancel: _prevStep,

          // custom tombol biar sesuai style kamu
          controlsBuilder: (context, details) {
            final isLast = _currentStep == 2;
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isLast ? "Register" : "Lanjut",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentStep == 0
                          ? null
                          : details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Kembali"),
                    ),
                  ),
                ],
              ),
            );
          },

          // definisi 3 step
          steps: [
            Step(
              title: const Text("Data Diri"),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _step1DataDiri(),
            ),
            Step(
              title: const Text("Kesehatan & Fisik"),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: _step2KesehatanFisik(),
            ),
            Step(
              title: const Text("Kontak Darurat"),
              isActive: _currentStep >= 2,
              content: _step3KontakDarurat(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const AuthRedirectText(isLogin: false),
      ],
    );
  }
}

//   Future<void> _handleRegisterButton() async {
//     final isValidForm = _formKey.currentState?.validate() ?? false;
//     if (!isValidForm) return;

//     try {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => const PopUpLoading(),
//       );

//       final user = UserModel(
//         email: _emailController.text.trim(),
//         phoneNumber: _phoneNumberController.text.trim(),
//         fullName: _fullNameController.text.trim(),
//         age: _isPharmacist ? 0 : int.tryParse(_ageController.text.trim()) ?? 0,
//         height: _isPharmacist
//             ? 0
//             : double.tryParse(_heightController.text.trim()) ?? 0.0,
//         weight: _isPharmacist
//             ? 0
//             : double.tryParse(_weightController.text.trim()) ?? 0.0,
//         medicalHistory: _isPharmacist ? const [] : _selectedMedicalHistory,
//         gender: gender,
//         drugAllergy: _isPharmacist ? const [] : _selectedDrugAllergy,
//         emergencyContact: _isPharmacist
//             ? EmergencyContactModel(
//                 name: '-',
//                 relationship: '-',
//                 phoneNumber: '-',
//               )
//             : EmergencyContactModel(
//                 name: _emergencyContactNameController.text.trim(),
//                 relationship: _emergencyContactRelationshipController.text
//                     .trim(),
//                 phoneNumber: _emergencyContactPhoneNumberController.text.trim(),
//               ),
//       );

//       final response = await _authService.register(
//         user: user,
//         password: _passwordController.text.trim(),
//         pharmacistCode: _isPharmacist
//             ? _pharmacistCodeController.text.trim()
//             : null,
//       );

//       if (!mounted) return;
//       Navigator.of(context).pop();

//       if (response.user != null) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const SplashScreen()),
//         );
//       } else {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text("Registrasi gagal")));
//       }
//     } catch (e) {
//       if (mounted) Navigator.of(context).pop();
//       if (mounted)
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Error: $e")));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: _formKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           TextFormFieldWithLabel(
//             label: "Nama Lengkap",
//             controller: _fullNameController,
//             validator: (v) => InputValidator.emptyField(v, "Nama"),
//           ),
//           const SizedBox(height: 10),
//           TextFormFieldWithLabel(
//             label: "Nomor Telepon Anda",
//             controller: _phoneNumberController,
//             validator: (v) => InputValidator.phoneNumber(v),
//           ),
//           const SizedBox(height: 10),
//           TextFormFieldWithLabel(
//             label: "Email",
//             controller: _emailController,
//             validator: (v) => InputValidator.email(v),
//           ),
//           const SizedBox(height: 10),
//           PasswordFormFieldWithLabel(
//             controller: _passwordController,
//             validator: (v) => InputValidator.minLength(v, "Password", 8),
//           ),
//           const SizedBox(height: 10),
//           GenderForm(
//             selectedGender: gender,
//             onChanged: (value) => setState(() => gender = value),
//           ),
//           if (_isPharmacist)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 10.0),
//               child: TextFormFieldWithLabel(
//                 label: "Kode Registrasi Apoteker",
//                 controller: _pharmacistCodeController,
//                 validator: (value) =>
//                     InputValidator.emptyField(value, "Kode Registrasi"),
//               ),
//             ),

//           if (!_isPharmacist) ...[
//             TextFormFieldWithLabel(
//               label: "Umur (Tahun)",
//               controller: _ageController,
//               validator: (v) => InputValidator.emptyField(v, "Umur"),
//             ),
//             const SizedBox(height: 10),
//             TextFormFieldWithLabel(
//               label: "Tinggi Badan (cm)",
//               controller: _heightController,
//               validator: (v) => InputValidator.emptyField(v, "Tinggi badan"),
//             ),
//             const SizedBox(height: 10),
//             TextFormFieldWithLabel(
//               label: "Berat Badan (kg)",
//               controller: _weightController,
//               validator: (v) => InputValidator.emptyField(v, "Berat badan"),
//             ),
//             const SizedBox(height: 10),
//             MultiSelectForm(
//               title: "Riwayat Penyakit",
//               hintText: "Masukkan penyakit",
//               selectedItems: _selectedMedicalHistory,
//               onChanged: (newList) =>
//                   setState(() => _selectedMedicalHistory = newList),
//             ),
//             const SizedBox(height: 10),
//             MultiSelectForm(
//               title: "Alergi Obat",
//               hintText: "Masukkan obat",
//               selectedItems: _selectedDrugAllergy,
//               onChanged: (list) => setState(() => _selectedDrugAllergy = list),
//             ),
//             const Divider(height: 20),
//             const Text(
//               "Kontak Darurat",
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 10),
//             TextFormFieldWithLabel(
//               label: "Nama Kontak",
//               controller: _emergencyContactNameController,
//               validator: (v) => InputValidator.emptyField(v, "Nama kontak"),
//             ),
//             const SizedBox(height: 10),
//             TextFormFieldWithLabel(
//               label: "Hubungan",
//               controller: _emergencyContactRelationshipController,
//               validator: (v) => InputValidator.emptyField(v, "Hubungan"),
//             ),
//             const SizedBox(height: 10),
//             TextFormFieldWithLabel(
//               label: "Nomor Telepon Kontak",
//               controller: _emergencyContactPhoneNumberController,
//               validator: (v) => InputValidator.phoneNumber(v),
//             ),
//             const SizedBox(height: 20),
//           ],
//           ElevatedButton(
//             onPressed: _handleRegisterButton,
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               backgroundColor: Colors.blue,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: const Text("Register", style: TextStyle(fontSize: 16)),
//           ),
//           const SizedBox(height: 10),
//           const AuthRedirectText(isLogin: false),
//         ],
//       ),
//     );
//   }
// }
