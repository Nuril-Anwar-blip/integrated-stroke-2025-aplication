import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'medication_history_screen.dart';
import 'models/medication_reminder.dart';

class MedicationReminderScreen extends StatefulWidget {
  const MedicationReminderScreen({super.key});

  @override
  State<MedicationReminderScreen> createState() =>
      _MedicationReminderScreenState();
}

class _MedicationReminderScreenState extends State<MedicationReminderScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final Stream<List<MedicationReminder>> _remindersStream;
  late FlutterLocalNotificationsPlugin _notifications;
  static const AndroidNotificationChannel _medChannel =
      AndroidNotificationChannel(
    'medication_channel',
    'Pengingat Obat',
    description: 'Notifikasi untuk pengingat minum obat',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    sound: RawResourceAndroidNotificationSound('alarm_sound'),
  );

  final List<String> _periodFilters = const [
    'Semua',
    'Pagi',
    'Siang',
    'Sore',
    'Malam',
  ];
  String _selectedPeriod = 'Semua';
  int _notificationIdCounter = 0;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _userId = _supabase.auth.currentUser?.id;
    if (_userId == null) {
      _remindersStream = Stream.value(const []);
    } else {
      _remindersStream = _supabase
          .from('medication_reminders')
          .stream(primaryKey: ['id'])
          .eq('user_id', _userId!)
          .order('time', ascending: true)
          .map(
            (rows) => rows
                .map(
                  (row) =>
                      MedicationReminder.fromMap(row as Map<String, dynamic>),
                )
                .toList(),
          );
    }
  }

  Future<void> _initializeNotifications() async {
    _notifications = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
    tz.initializeTimeZones();
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(_medChannel);
      try {
        await (androidImpl as dynamic).requestNotificationsPermission();
      } catch (_) {
        // Fallback: method not available on this plugin version.
      }
      try {
        await androidImpl.requestExactAlarmsPermission();
      } catch (_) {
        // API < 33 will throw; safe to ignore.
      }
    }
  }

  Future<void> _scheduleNotification(
    int id,
    String name,
    TimeOfDay time,
  ) async {
    final now = TimeOfDay.now();
    Duration diff = Duration(
      hours: time.hour - now.hour,
      minutes: time.minute - now.minute,
    );
    if (diff.isNegative) diff += const Duration(days: 1);

    final scheduledTime = tz.TZDateTime.now(tz.local).add(diff);

    const androidDetails = AndroidNotificationDetails(
      'medication_channel',
      'Pengingat Obat',
      channelDescription: 'Notifikasi untuk pengingat minum obat',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      ticker: 'MedicationReminder',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id,
      'Waktunya minum obat!',
      'Minum obat: $name sekarang!',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _testAlarmNow() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Tes Alarm',
      channelDescription: 'Coba suara alarm sekarang',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      999,
      'Tes Alarm',
      'Alarm berbunyi sekarang',
      details,
    );
  }

  Future<void> _addMedication() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masuk terlebih dahulu untuk menambah pengingat.'),
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddMedicationDialog(),
    );
    if (result == null) return;

    final TimeOfDay time = result['time'] as TimeOfDay;
    final payload = {
      'user_id': _userId,
      'name': result['name'],
      'dose': result['dose'],
      'note': result['note'],
      'time': _toDbTime(time),
      'period': _resolvePeriod(time),
      'taken': false,
    };

    try {
      final inserted =
          await _supabase
                  .from('medication_reminders')
                  .insert(payload)
                  .select()
                  .single()
              as Map<String, dynamic>;
      await _scheduleNotification(
        _notificationIdCounter++,
        inserted['name'] as String,
        time,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengingat ${inserted['name']} disetel pada ${time.format(context)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menambah pengingat: $e')));
    }
  }

  Future<void> _toggleTaken(MedicationReminder reminder) async {
    try {
      await _supabase
          .from('medication_reminders')
          .update({'taken': !reminder.taken})
          .eq('id', reminder.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
    }
  }

  void _openHistory() {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masuk terlebih dahulu untuk melihat riwayat.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicationHistoryScreen(userId: _userId!),
      ),
    );
  }

  List<MedicationReminder> _filterReminders(
    List<MedicationReminder> reminders,
  ) {
    if (_selectedPeriod == 'Semua') return reminders;
    return reminders.where((r) => r.period == _selectedPeriod).toList();
  }

  MedicationReminder? _upcomingReminder(List<MedicationReminder> reminders) {
    if (reminders.isEmpty) return null;
    final nowMinutes = _timeToMinutes(TimeOfDay.now());
    try {
      return reminders.firstWhere(
        (r) => !r.taken && _timeToMinutes(r.time) >= nowMinutes,
      );
    } catch (_) {
      final fallback = reminders.where((r) => !r.taken).toList();
      return fallback.isNotEmpty ? fallback.first : null;
    }
  }

  int _timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String _timeUntil(TimeOfDay time) {
    final now = TimeOfDay.now();
    var diff = _timeToMinutes(time) - _timeToMinutes(now);
    if (diff < 0) diff += 24 * 60;
    final hours = diff ~/ 60;
    final minutes = diff % 60;
    if (hours == 0) return '$minutes mnt lagi';
    if (minutes == 0) return '$hours jam lagi';
    return '$hours j $minutes m lagi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.teal.shade900,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.teal.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Pengingat Obat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: 'Riwayat Pengingat',
            onPressed: _openHistory,
          ),
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
            tooltip: 'Coba bunyi alarm',
            onPressed: _testAlarmNow,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMedication,
        backgroundColor: Colors.teal.shade500,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Obat'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.teal.shade50,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<List<MedicationReminder>>(
          stream: _remindersStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final reminders = snapshot.data ?? const [];
            final filtered = _filterReminders(reminders);
            final upcoming = _upcomingReminder(filtered);
            final total = reminders.length;
            final completed = reminders.where((r) => r.taken).length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 140),
              children: [
                _SummaryCard(completed: completed, total: total),
                const SizedBox(height: 14),
                _PeriodSelector(
                  periods: _periodFilters,
                  selected: _selectedPeriod,
                  onSelected: (value) => setState(() => _selectedPeriod = value),
                ),
                const SizedBox(height: 14),
                if (upcoming != null)
                  _UpcomingCard(
                    name: upcoming.name,
                    dose: upcoming.dose?.isEmpty ?? true
                        ? 'Tanpa dosis'
                        : upcoming.dose!,
                    timeLabel: upcoming.time.format(context),
                    countdown: _timeUntil(upcoming.time),
                    accent: Colors.orangeAccent,
                  )
                else if (total > 0)
                  const _UpcomingCard(
                    name: 'Semua aman',
                    dose: 'Tidak ada jadwal dekat',
                    timeLabel: '—',
                    countdown: 'Istirahat sejenak',
                    accent: Colors.green,
                  ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const _EmptyStateCard(
                    message:
                        'Belum ada pengingat. Tekan Tambah Obat atau buat jadwal baru.',
                  )
                else
                  ...filtered.map(
                    (reminder) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MedicationCard(
                        reminder: reminder,
                        onToggle: () => _toggleTaken(reminder),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _resolvePeriod(TimeOfDay time) {
    if (time.hour >= 5 && time.hour < 11) return 'Pagi';
    if (time.hour >= 11 && time.hour < 15) return 'Siang';
    if (time.hour >= 15 && time.hour < 19) return 'Sore';
    return 'Malam';
  }

  String _toDbTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
}

/// ========================
/// UI COMPONENTS
/// ========================
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.completed, required this.total});
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [Colors.teal.shade500, Colors.teal.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.health_and_safety, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text(
                'Progres Hari Ini',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            total == 0 ? 'Belum ada jadwal' : '$completed dari $total obat',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.periods,
    required this.selected,
    required this.onSelected,
  });
  final List<String> periods;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods
            .map(
              (period) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(period),
                  selected: selected == period,
                  onSelected: (_) => onSelected(period),
                  selectedColor: Colors.teal.shade100,
                  labelStyle: TextStyle(
                    color: selected == period ? Colors.teal.shade800 : Colors.black87,
                    fontWeight: selected == period
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: selected == period
                          ? Colors.teal.shade300
                          : Colors.grey.shade200,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.name,
    required this.dose,
    required this.timeLabel,
    required this.countdown,
    required this.accent,
  });
  final String name, dose, timeLabel, countdown;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.alarm, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dose,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        timeLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          countdown,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.teal.shade50,
                child: Icon(Icons.medication_outlined,
                    size: 40, color: Colors.teal.shade400),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.reminder, required this.onToggle});
  final MedicationReminder reminder;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final accent = reminder.taken ? Colors.green : Colors.blue;
    final note = reminder.note?.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: reminder.taken
              ? Colors.green.withOpacity(0.2)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withOpacity(0.12),
                foregroundColor: accent,
                child: Icon(
                  reminder.taken
                      ? Icons.verified
                      : Icons.medication_liquid_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      reminder.dose?.isEmpty ?? true
                          ? 'Dosis belum diisi'
                          : reminder.dose!,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    if (note != null && note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        note,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  reminder.period,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                reminder.time.format(context),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              Text(
                reminder.taken ? 'Sudah diminum' : 'Belum diminum',
                style: TextStyle(
                  color: reminder.taken ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: onToggle,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  reminder.taken ? Colors.grey.shade200 : Colors.teal.shade50,
              foregroundColor:
                  reminder.taken ? Colors.grey.shade800 : Colors.teal.shade700,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              reminder.taken ? Icons.refresh : Icons.check_circle_outline,
            ),
            label: Text(reminder.taken ? 'Ulangi Jadwal' : 'Tandai diminum'),
          ),
        ],
      ),
    );
  }
}

class _AddMedicationDialog extends StatefulWidget {
  const _AddMedicationDialog();
  @override
  State<_AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<_AddMedicationDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text('Tambah Pengingat'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama obat',
                  filled: true,
                  fillColor: Color(0xfff7f9fb),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _doseController,
                decoration: const InputDecoration(
                  labelText: 'Dosis',
                  filled: true,
                  fillColor: Color(0xfff7f9fb),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  filled: true,
                  fillColor: Color(0xfff7f9fb),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedTime == null
                          ? 'Jam belum dipilih'
                          : 'Jam: ${_selectedTime!.format(context)}',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => _selectedTime = picked);
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Pilih Jam'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isEmpty || _selectedTime == null) return;
              Navigator.pop(context, {
                'name': _nameController.text,
                'dose': _doseController.text,
                'note': _noteController.text,
                'time': _selectedTime,
              });
            },
            child: const Text('Simpan'),
          ),
        ],
      );
}
