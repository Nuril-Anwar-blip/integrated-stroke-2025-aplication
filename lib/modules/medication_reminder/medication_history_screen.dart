import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/medication_reminder.dart';

class MedicationHistoryScreen extends StatefulWidget {
  const MedicationHistoryScreen({super.key, required this.userId});

  final String userId;

  @override
  State<MedicationHistoryScreen> createState() =>
      _MedicationHistoryScreenState();
}

class _MedicationHistoryScreenState extends State<MedicationHistoryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final Stream<List<MedicationReminder>> _historyStream;

  @override
  void initState() {
    super.initState();
    _historyStream = _supabase
        .from('medication_reminders')
        .stream(primaryKey: ['id'])
        .eq('user_id', widget.userId)
        .order('updated_at', ascending: false)
        .map(
          (rows) => rows
              .map(
                (row) =>
                    MedicationReminder.fromMap(row as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  Future<void> _deleteReminder(String id) async {
    try {
      await _supabase.from('medication_reminders').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pengingat dihapus')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pengingat Obat')),
      body: StreamBuilder<List<MedicationReminder>>(
        stream: _historyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reminders = snapshot.data ?? const [];
          if (reminders.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada riwayat pengingat.\nTambahkan pengingat terlebih dahulu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return Dismissible(
                key: ValueKey(reminder.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Hapus pengingat?'),
                          content: Text(
                            'Anda yakin ingin menghapus pengingat ${reminder.name}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (_) => _deleteReminder(reminder.id),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: reminder.taken
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    foregroundColor: reminder.taken
                        ? Colors.green
                        : Colors.orange,
                    child: Icon(reminder.taken ? Icons.check : Icons.alarm),
                  ),
                  title: Text(reminder.name),
                  subtitle: Text(
                    '${reminder.dose?.isEmpty ?? true ? 'Tanpa dosis' : reminder.dose}\n'
                    '${reminder.time.format(context)} • ${reminder.period}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: reminders.length,
          );
        },
      ),
    );
  }
}
