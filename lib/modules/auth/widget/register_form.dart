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

enum RegisterRole { patient, pharmacist }

class RegisterForm extends StatefulWidget {
  final RegisterRole role;
  const RegisterForm({super.key, this.role = RegisterRole.patient});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  late final GlobalKey<FormState> _formKey;
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

  final _authService = AuthService();

  List<String> _selectedMedicalHistory = [];
  List<String> _selectedDrugAllergy = [];
  String gender = "male";
  bool get _isPharmacist => widget.role == RegisterRole.pharmacist;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
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

  Future<void> _handleRegisterButton() async {
    final isValidForm = _formKey.currentState?.validate() ?? false;
    if (!isValidForm) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopUpLoading(),
      );

      final user = UserModel(
        email: _emailController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        fullName: _fullNameController.text.trim(),
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

      final response = await _authService.register(
        user: user,
        password: _passwordController.text.trim(),
        pharmacistCode: _isPharmacist
            ? _pharmacistCodeController.text.trim()
            : null,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (response.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Registrasi gagal")));
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
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
            label: "Nama Lengkap",
            controller: _fullNameController,
            validator: (v) => InputValidator.emptyField(v, "Nama"),
          ),
          const SizedBox(height: 10),
          TextFormFieldWithLabel(
            label: "Nomor Telepon Anda",
            controller: _phoneNumberController,
            validator: (v) => InputValidator.phoneNumber(v),
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

          if (!_isPharmacist) ...[
            TextFormFieldWithLabel(
              label: "Umur (Tahun)",
              controller: _ageController,
              validator: (v) => InputValidator.emptyField(v, "Umur"),
            ),
            const SizedBox(height: 10),
            TextFormFieldWithLabel(
              label: "Tinggi Badan (cm)",
              controller: _heightController,
              validator: (v) => InputValidator.emptyField(v, "Tinggi badan"),
            ),
            const SizedBox(height: 10),
            TextFormFieldWithLabel(
              label: "Berat Badan (kg)",
              controller: _weightController,
              validator: (v) => InputValidator.emptyField(v, "Berat badan"),
            ),
            const SizedBox(height: 10),
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
            const Divider(height: 20),
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
            const SizedBox(height: 20),
          ],
          ElevatedButton(
            onPressed: _handleRegisterButton,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Register", style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 10),
          const AuthRedirectText(isLogin: false),
        ],
      ),
    );
  }
}
