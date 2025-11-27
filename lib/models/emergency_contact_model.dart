// Lokasi: models/emergency_contact_model.dart

class EmergencyContactModel {
  final String name;
  final String phoneNumber;
  final String relationship;

  EmergencyContactModel({
    required this.name,
    required this.phoneNumber,
    required this.relationship,
  });

  // Menerima Map<String, dynamic> dari Supabase
  factory EmergencyContactModel.fromMap(Map<String, dynamic> map) {
    return EmergencyContactModel(
      name: map['name'] as String? ?? '',
      phoneNumber: map['phone_number'] as String? ?? '',
      relationship: map['relationship'] as String? ?? '',
    );
  }

  // Mengirim Map<String, dynamic> ke Supabase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'relationship': relationship,
    };
  }
}
