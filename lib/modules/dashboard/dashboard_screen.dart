import 'dart:async';
import 'package:flutter/material.dart';
import 'package:integrated_strokes2025/modules/emergency_location/emergency_location_screen.dart';
import 'package:integrated_strokes2025/styles/colors/app_color.dart';
import 'package:integrated_strokes2025/modules/community/community_screen.dart';
import 'package:integrated_strokes2025/modules/consultation/patient_chat_dashboard_screen.dart';
import 'package:integrated_strokes2025/modules/profile/profile_screen.dart';
import 'package:integrated_strokes2025/modules/medication_reminder/medication_reminder_screen.dart';
import 'package:integrated_strokes2025/modules/navbar/navbar.dart';
import 'package:integrated_strokes2025/modules/exercise/exercise_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _HomeTab(),
    CommunityScreen(),
    PatientChatDashboardScreen(),
    ProfileScreen(),
  ];

  void _onNavTap(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return CustomNavbar(
      currentIndex: _currentIndex,
      onTap: _onNavTap,
      body: SafeArea(child: _pages[_currentIndex]),
    );
  }
}

/// ===============================
/// HOME TAB — REALTIME SENSOR DATA
/// ===============================
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _supabase = Supabase.instance.client;

  late final StreamController<_DashboardStats> _statsController;
  late final Stream<_DashboardStats> _statsStream;
  RealtimeChannel? _sensorChannel;
  String? _userId;
  _DashboardStats _currentStats = _DashboardStats.empty();

  @override
  void initState() {
    super.initState();
    _statsController = StreamController<_DashboardStats>.broadcast();
    _statsStream = _statsController.stream;
    _initializeRealtimeListener();
  }

  Future<void> _initializeRealtimeListener() async {
    _userId = _supabase.auth.currentUser?.id;
    if (_userId == null) {
      _statsController.add(_DashboardStats.empty());
      return;
    }

    // Ambil data awal
    await _fetchLatestHeartRate();

    // Listen untuk perubahan data baru (realtime)
    _sensorChannel = _supabase.channel('realtime_sensor_data_$_userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'sensor_data',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: _userId!,
        ),
        callback: (payload) async {
          final newRow = payload.newRecord;
          if (newRow['heart_rate'] != null) {
            final newHeartRate = newRow['heart_rate'].toString();
            _updateStats(heartRate: '$newHeartRate bpm');
          } else {
            await _fetchLatestHeartRate();
          }
        },
      )
      ..subscribe();

    debugPrint("✅ Realtime listener aktif untuk user $_userId");
  }

  /// Ambil data terbaru (backup jika belum ada event realtime)
  Future<void> _fetchLatestHeartRate() async {
    if (_userId == null) return;
    try {
      final response = await _supabase
          .from('sensor_data')
          .select('heart_rate, value, type')
          .eq('user_id', _userId!)
          .order('timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      final hrLabel = _formatHeartRate(response);
      if (hrLabel != null) {
        _updateStats(heartRate: hrLabel);
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch heart rate: $e');
    }
  }

  /// Format nilai heart rate agar tampil rapi
  String? _formatHeartRate(Map<String, dynamic>? response) {
    if (response == null) return null;
    final hr = response['heart_rate'];
    if (hr == null) return null;
    return "$hr bpm";
  }

  /// Update data di StreamController agar UI auto-refresh
  void _updateStats({String? heartRate, String? medication}) {
    _currentStats = _DashboardStats(
      heartRate: heartRate ?? _currentStats.heartRate,
      medicationFrequency: medication ?? _currentStats.medicationFrequency,
    );
    _statsController.add(_currentStats);
  }

  @override
  void dispose() {
    _sensorChannel?.unsubscribe();
    if (_sensorChannel != null) {
      _supabase.removeChannel(_sensorChannel!);
    }
    _statsController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 72;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
      children: [
        const _TopBar(),
        const SizedBox(height: 14),
        StreamBuilder<_DashboardStats>(
          stream: _statsStream,
          builder: (context, snapshot) {
            final stats = snapshot.data ?? _DashboardStats.empty();
            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Detak Jantung',
                    value: stats.heartRate,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Obat',
                    value: stats.medicationFrequency,
                    color: Colors.green,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Fitur Utama'),
        const SizedBox(height: 10),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _FeatureCard(
              icon: Icons.medication,
              label: 'Obat',
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicationReminderScreen(),
                ),
              ),
            ),
            _FeatureCard(
              icon: Icons.fitness_center,
              label: 'Latihan',
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExerciseScreen()),
              ),
            ),
            _FeatureCard(
              icon: Icons.groups,
              label: 'Komunitas',
              color: Colors.deepOrange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CommunityScreen()),
              ),
            ),
            _FeatureCard(
              icon: Icons.chat,
              label: 'Chat Apoteker',
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PatientChatDashboardScreen(),
                ),
              ),
            ),
            _FeatureCard(
              icon: Icons.location_on,
              label: 'Lokasi Darurat',
              color: Colors.redAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EmergencyLocationScreen(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ======== MODEL =========
class _DashboardStats {
  final String heartRate;
  final String medicationFrequency;

  const _DashboardStats({
    required this.heartRate,
    required this.medicationFrequency,
  });

  factory _DashboardStats.fromMap(Map<String, dynamic> map) {
    final hr = map['heart_rate'];
    final heartRateValue = hr == null ? '—' : '${hr.toString()} bpm';
    return _DashboardStats(heartRate: heartRateValue, medicationFrequency: '—');
  }

  factory _DashboardStats.empty() =>
      const _DashboardStats(heartRate: '—', medicationFrequency: '—');
}

/// ======== UI COMPONENTS =========
class _TopBar extends StatelessWidget {
  const _TopBar();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 6),
      child: Row(
        children: [
          const CircleAvatar(radius: 22, child: Icon(Icons.person_outline)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                SizedBox(height: 4),
                Text(
                  'Integrated Stroke',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final Color color;
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });
  const _StatCard.skeleton() : title = '', value = '', color = Colors.grey;
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 80, maxHeight: 92),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(Icons.monitor_heart, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.95), color.withOpacity(0.7)],
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              child: Icon(icon, color: color),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
