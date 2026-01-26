class CommonMedication {
  final String name;
  final String? defaultDose;
  final String category;

  const CommonMedication({
    required this.name,
    this.defaultDose,
    required this.category,
  });
}

class CommonMedications {
  static const List<CommonMedication> list = [
    // Obat Stroke - Antiplatelet
    CommonMedication(
      name: 'Aspirin',
      defaultDose: '100 mg',
      category: 'Antiplatelet',
    ),
    CommonMedication(
      name: 'Clopidogrel',
      defaultDose: '75 mg',
      category: 'Antiplatelet',
    ),
    CommonMedication(
      name: 'Ticlopidine',
      defaultDose: '250 mg',
      category: 'Antiplatelet',
    ),
    // Obat Stroke - Statin
    CommonMedication(
      name: 'Atorvastatin',
      defaultDose: '20 mg',
      category: 'Statin',
    ),
    CommonMedication(
      name: 'Simvastatin',
      defaultDose: '20 mg',
      category: 'Statin',
    ),
    CommonMedication(
      name: 'Rosuvastatin',
      defaultDose: '10 mg',
      category: 'Statin',
    ),
    // Obat Stroke - Antihipertensi
    CommonMedication(
      name: 'Losartan',
      defaultDose: '50 mg',
      category: 'Antihipertensi',
    ),
    CommonMedication(
      name: 'Amlodipine',
      defaultDose: '5 mg',
      category: 'Antihipertensi',
    ),
    CommonMedication(
      name: 'Captopril',
      defaultDose: '25 mg',
      category: 'Antihipertensi',
    ),
    CommonMedication(
      name: 'Enalapril',
      defaultDose: '10 mg',
      category: 'Antihipertensi',
    ),
    CommonMedication(
      name: 'Lisinopril',
      defaultDose: '10 mg',
      category: 'Antihipertensi',
    ),
    CommonMedication(
      name: 'Valsartan',
      defaultDose: '80 mg',
      category: 'Antihipertensi',
    ),
    // Obat Stroke - Antikoagulan
    CommonMedication(
      name: 'Warfarin',
      defaultDose: '2.5 mg',
      category: 'Antikoagulan',
    ),
    CommonMedication(
      name: 'Rivaroxaban',
      defaultDose: '20 mg',
      category: 'Antikoagulan',
    ),
    CommonMedication(
      name: 'Apixaban',
      defaultDose: '5 mg',
      category: 'Antikoagulan',
    ),
    // Obat Stroke - Diuretik
    CommonMedication(
      name: 'Furosemide',
      defaultDose: '40 mg',
      category: 'Diuretik',
    ),
    CommonMedication(
      name: 'Hydrochlorothiazide',
      defaultDose: '25 mg',
      category: 'Diuretik',
    ),
    // Obat Stroke - Antidiabetes
    CommonMedication(
      name: 'Metformin',
      defaultDose: '500 mg',
      category: 'Antidiabetes',
    ),
    CommonMedication(
      name: 'Glibenclamide',
      defaultDose: '5 mg',
      category: 'Antidiabetes',
    ),
    // Obat Stroke - Neuroprotektor
    CommonMedication(
      name: 'Citicoline',
      defaultDose: '500 mg',
      category: 'Neuroprotektor',
    ),
    CommonMedication(
      name: 'Piracetam',
      defaultDose: '800 mg',
      category: 'Neuroprotektor',
    ),
    // Obat Stroke - Lainnya
    CommonMedication(
      name: 'Omeprazole',
      defaultDose: '20 mg',
      category: 'Antasida',
    ),
    CommonMedication(
      name: 'Paracetamol',
      defaultDose: '500 mg',
      category: 'Analgesik',
    ),
    CommonMedication(
      name: 'Ibuprofen',
      defaultDose: '400 mg',
      category: 'Analgesik',
    ),
  ];

  static List<String> get names => list.map((m) => m.name).toList();
  
  static CommonMedication? findByName(String name) {
    try {
      return list.firstWhere((m) => m.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}

