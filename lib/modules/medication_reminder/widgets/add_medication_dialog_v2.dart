import 'package:flutter/material.dart';
import '../models/common_medications.dart';

class AddMedicationDialogV2 extends StatefulWidget {
  const AddMedicationDialogV2({super.key});

  @override
  State<AddMedicationDialogV2> createState() => _AddMedicationDialogV2State();
}

class _AddMedicationDialogV2State extends State<AddMedicationDialogV2> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  String? _selectedMedication;
  bool _isCustomMedication = false;
  String _frequency = '1x sehari';
  List<TimeOfDay> _selectedTimes = [];

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onMedicationChanged(String? value) {
    setState(() {
      _selectedMedication = value;
      _isCustomMedication = value == 'Lainnya';
      if (!_isCustomMedication && value != null) {
        final med = CommonMedications.findByName(value);
        if (med != null && med.defaultDose != null) {
          _doseController.text = med.defaultDose!;
        }
      } else {
        _doseController.clear();
      }
      _nameController.text = _isCustomMedication ? '' : (value ?? '');
    });
  }

  void _onFrequencyChanged(String value) {
    setState(() {
      _frequency = value;
      _selectedTimes.clear();
      _generateTimes();
    });
  }

  void _generateTimes() {
    _selectedTimes.clear();
    
    switch (_frequency) {
      case '1x sehari':
        _selectedTimes.add(const TimeOfDay(hour: 8, minute: 0));
        break;
      case '2x sehari':
        _selectedTimes.add(const TimeOfDay(hour: 8, minute: 0));
        _selectedTimes.add(const TimeOfDay(hour: 20, minute: 0));
        break;
      case '3x sehari':
        _selectedTimes.add(const TimeOfDay(hour: 7, minute: 0));
        _selectedTimes.add(const TimeOfDay(hour: 12, minute: 0));
        _selectedTimes.add(const TimeOfDay(hour: 18, minute: 0));
        break;
      case '4x sehari':
        _selectedTimes.add(const TimeOfDay(hour: 6, minute: 0));
        _selectedTimes.add(const TimeOfDay(hour: 12, minute: 0));
        _selectedTimes.add(const TimeOfDay(hour: 18, minute: 0));
        _selectedTimes.add(const TimeOfDay(hour: 22, minute: 0));
        break;
      default:
        _selectedTimes.add(const TimeOfDay(hour: 8, minute: 0));
    }
  }

  Future<void> _editTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
    );
    if (picked != null) {
      setState(() {
        _selectedTimes[index] = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _generateTimes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade400, Colors.teal.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medication_liquid_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tambah Pengingat Obat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Obat Selection
                    const Text(
                      'Pilih Obat',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedMedication,
                      decoration: InputDecoration(
                        hintText: 'Pilih dari daftar atau ketik manual',
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        ...CommonMedications.list.map((med) => DropdownMenuItem(
                              value: med.name,
                              child: Text('${med.name} (${med.category})'),
                            )),
                        const DropdownMenuItem(
                          value: 'Lainnya',
                          child: Text('Lainnya (Ketik manual)'),
                        ),
                      ],
                      onChanged: _onMedicationChanged,
                    ),
                    if (_isCustomMedication) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Obat',
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Dosis
                    const Text(
                      'Dosis',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _doseController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: 100 mg, 1 tablet',
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Frekuensi
                    const Text(
                      'Frekuensi Minum',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _frequency,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: '1x sehari', child: Text('1x sehari')),
                        DropdownMenuItem(value: '2x sehari', child: Text('2x sehari')),
                        DropdownMenuItem(value: '3x sehari', child: Text('3x sehari')),
                        DropdownMenuItem(value: '4x sehari', child: Text('4x sehari')),
                      ],
                      onChanged: (value) {
                        if (value != null) _onFrequencyChanged(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Jam-jam yang dipilih
                    if (_selectedTimes.isNotEmpty) ...[
                      const Text(
                        'Waktu Minum Obat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedTimes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final time = entry.value;
                          return Chip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(time.format(context)),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _editTime(index),
                                  child: const Icon(Icons.edit, size: 16),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.teal.withOpacity(0.1),
                            labelStyle: TextStyle(color: Colors.teal.shade700),
                            onDeleted: null,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Catatan
                    const Text(
                      'Catatan (Opsional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Setelah makan, Sebelum tidur',
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = _isCustomMedication
                            ? _nameController.text
                            : (_selectedMedication ?? '');
                        if (name.isEmpty || _selectedTimes.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mohon lengkapi semua field yang wajib'),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context, {
                          'name': name,
                          'dose': _doseController.text,
                          'note': _noteController.text,
                          'times': _selectedTimes,
                          'frequency': _frequency,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

