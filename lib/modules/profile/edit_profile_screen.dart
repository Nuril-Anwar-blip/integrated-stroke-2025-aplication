// Lokasi: screens/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String phoneNumber;
  final int? age;
  final String? gender;
  final double? weight;
  final double? height;
  final String? medicalHistory;
  final String? drugAllergy;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;
  final String? photoUrl;

  const EditProfileScreen({
    Key? key,
    required this.name,
    required this.phoneNumber,
    this.age,
    this.gender,
    this.weight,
    this.height,
    this.medicalHistory,
    this.drugAllergy,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.photoUrl,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _medicalHistoryController;
  late TextEditingController _drugAllergyController;
  late TextEditingController _emergencyContactNameController;
  late TextEditingController _emergencyContactPhoneController;
  late TextEditingController _emergencyContactRelationshipController;
  String? _gender;
  String? _photoUrl;
  File? _pickedImage;
  bool _isUploading = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _phoneController = TextEditingController(text: widget.phoneNumber);
    _ageController = TextEditingController(text: widget.age?.toString() ?? '');
    _weightController = TextEditingController(
      text: widget.weight?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: widget.height?.toString() ?? '',
    );
    _medicalHistoryController = TextEditingController(
      text: widget.medicalHistory ?? '',
    );
    _drugAllergyController = TextEditingController(
      text: widget.drugAllergy ?? '',
    );
    _emergencyContactNameController = TextEditingController(
      text: widget.emergencyContactName ?? '',
    );
    _emergencyContactPhoneController = TextEditingController(
      text: widget.emergencyContactPhone ?? '',
    );
    _emergencyContactRelationshipController = TextEditingController(
      text: widget.emergencyContactRelationship ?? '',
    );
    _gender = widget.gender;
    _photoUrl = widget.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _medicalHistoryController.dispose();
    _drugAllergyController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _emergencyContactRelationshipController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (picked != null) {
        if (!mounted) return;
        setState(() => _pickedImage = File(picked.path));
        await _uploadImageToSupabase(_pickedImage!);
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _uploadImageToSupabase(File file) async {
    setState(() => _isUploading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isUploading = false);
      return;
    }

    final path =
        '${user.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storage = Supabase.instance.client.storage.from('profile_pictures');

    try {
      final bytes = await file.readAsBytes();
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );
      final url = storage.getPublicUrl(path);
      if (!mounted) return;
      setState(() => _photoUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal upload foto: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _saveProfile() {
    List<String> _parseList(String text) {
      if (text.trim().isEmpty) return [];
      return text
          .split(',')
          .map((e) => e.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    final dataToReturn = {
      'name': _nameController.text,
      'phoneNumber': _phoneController.text,
      'age': int.tryParse(_ageController.text),
      'gender': _gender,
      'weight': double.tryParse(_weightController.text),
      'height': double.tryParse(_heightController.text),
      'medicalHistory': _parseList(_medicalHistoryController.text),
      'drugAllergy': _parseList(_drugAllergyController.text),
      'emergencyContactName': _emergencyContactNameController.text,
      'emergencyContactPhone': _emergencyContactPhoneController.text,
      'emergencyContactRelationship':
          _emergencyContactRelationshipController.text,
      'photoUrl': _photoUrl,
    };
    Navigator.pop(context, dataToReturn);
  }

  Widget _buildAvatarPicker(BuildContext context) {
    ImageProvider? provider;
    if (_pickedImage != null) {
      provider = FileImage(_pickedImage!);
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      provider = NetworkImage(_photoUrl!);
    }

    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: provider,
                  child: provider == null
                      ? const Icon(Icons.person, size: 58, color: Colors.grey)
                      : null,
                ),
              ),
              Positioned(
                bottom: 10,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploading || _isPickingImage ? null : _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade500,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              if (_isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(80),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Perbarui foto agar apoteker mudah mengenali Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.9)),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
            ],
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    final options = {'male': 'Laki-laki', 'female': 'Perempuan'};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jenis Kelamin',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: options.entries.map((entry) {
            final selected = _gender == entry.key;
            return ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              selectedColor: Colors.teal.shade100,
              onSelected: (value) {
                if (value) {
                  setState(() => _gender = entry.key);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil'), centerTitle: true),
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatarPicker(context),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: 'Informasi Pribadi',
                        subtitle: 'Data ini membantu apoteker mengenal Anda.',
                        children: [
                          _buildTextField(
                            _nameController,
                            'Nama Lengkap',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            _phoneController,
                            'Nomor Telepon',
                            keyboardType: TextInputType.phone,
                            icon: Icons.phone_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildGenderSelector(),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _ageController,
                                  'Umur',
                                  keyboardType: TextInputType.number,
                                  icon: Icons.cake_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  _heightController,
                                  'Tinggi (cm)',
                                  keyboardType: TextInputType.number,
                                  icon: Icons.height,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            _weightController,
                            'Berat (kg)',
                            keyboardType: TextInputType.number,
                            icon: Icons.monitor_weight_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildSectionCard(
                        title: 'Kondisi Medis',
                        subtitle:
                            'Berbagi informasi agar rekomendasi obat lebih tepat.',
                        children: [
                          _buildTextField(
                            _medicalHistoryController,
                            'Riwayat Penyakit',
                            hint:
                                'Pisahkan dengan koma, contoh: hipertensi, diabetes',
                            icon: Icons.history_edu_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            _drugAllergyController,
                            'Alergi Obat',
                            hint:
                                'Pisahkan dengan koma, contoh: aspirin, parasetamol',
                            icon: Icons.vaccines_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildSectionCard(
                        title: 'Kontak Darurat',
                        subtitle: 'Kami hubungi saat keadaan genting.',
                        children: [
                          _buildTextField(
                            _emergencyContactNameController,
                            'Nama Kontak',
                            icon: Icons.person_pin_circle_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            _emergencyContactPhoneController,
                            'Nomor Telepon',
                            keyboardType: TextInputType.phone,
                            icon: Icons.phone_in_talk_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            _emergencyContactRelationshipController,
                            'Hubungan',
                            hint: 'Contoh: Ayah, Saudara',
                            icon: Icons.handshake_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Simpan Perubahan'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isUploading ? null : _saveProfile,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    IconData? icon,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.teal.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
      ),
    );
  }
}
