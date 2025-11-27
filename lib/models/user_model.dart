import 'dart:convert';
import 'emergency_contact_model.dart'; // Pastikan path import ini benar

class UserModel {
  final String? id;
  final String email;
  final String fullName;
  final int age;
  final double height;
  final double weight;
  final String gender;
  final String phoneNumber;
  final List<String> medicalHistory;
  final List<String> drugAllergy;
  final EmergencyContactModel emergencyContact;
  final String? photoUrl;

  UserModel({
    this.id,
    required this.email,
    required this.fullName,
    required this.age,
    required this.height,
    required this.weight,
    required this.gender,
    required this.phoneNumber,
    required this.medicalHistory,
    required this.drugAllergy,
    required this.emergencyContact,
    this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Fungsi bantuan untuk parsing yang lebih aman
    List<String> _parseListFromMap(dynamic data) {
      if (data == null) return [];
      // Jika data adalah String (format lama), decode dulu
      if (data is String) {
        if (data.isEmpty) return [];
        final decoded = jsonDecode(data);
        return List<String>.from(decoded);
      }
      // Jika data sudah List (format baru), langsung gunakan
      if (data is List) {
        return List<String>.from(data);
      }
      return [];
    }

    return UserModel(
      id: map['id'] as String?,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      age: map['age'] as int? ?? 0,
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      gender: map['gender'] as String? ?? 'male',
      phoneNumber: map['phone_number'] as String? ?? '',

      // Menggunakan fungsi bantuan yang aman
      medicalHistory: _parseListFromMap(map['medical_history']),
      drugAllergy: _parseListFromMap(map['drug_allergy']),

      emergencyContact:
          map['emergency_contact'] != null && map['emergency_contact'] is Map
          ? EmergencyContactModel.fromMap(map['emergency_contact'])
          : EmergencyContactModel(name: '', phoneNumber: '', relationship: ''),

      photoUrl: map['photo_url'] as String?,
    );
  }

  // Mengirim data ke Supabase dengan format yang benar untuk `jsonb`
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
      'phone_number': phoneNumber,
      'photo_url': photoUrl, // Penting: photoUrl sudah dimasukkan
      // Kirim sebagai List<String> asli, BUKAN string JSON
      'medical_history': medicalHistory,
      'drug_allergy': drugAllergy,

      // Kirim sebagai Map<String, dynamic> asli, BUKAN string JSON
      'emergency_contact': emergencyContact.toMap(),
    };
  }

  // Fungsi copyWith untuk kemudahan modifikasi objek
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    int? age,
    double? height,
    double? weight,
    String? gender,
    String? phoneNumber,
    List<String>? medicalHistory,
    List<String>? drugAllergy,
    EmergencyContactModel? emergencyContact,
    String? photoUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      drugAllergy: drugAllergy ?? this.drugAllergy,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
