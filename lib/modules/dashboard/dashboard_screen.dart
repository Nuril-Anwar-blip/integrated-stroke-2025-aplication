import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// pages sesuai project kamu
import 'package:integrated_stroke/modules/community/community_screen.dart';
import 'package:integrated_stroke/modules/consultation/patient_chat_dashboard_screen.dart';
import 'package:integrated_stroke/modules/profile/profile_screen.dart';
import 'package:integrated_stroke/widgets/floating_navbar.dart';

// fitur home
import 'package:integrated_stroke/modules/emergency_location/emergency_location_screen.dart';
import 'package:integrated_stroke/modules/exercise/exercise_screen.dart';
import 'package:integrated_stroke/modules/medication_reminder/medication_reminder_screen.dart';
import 'package:integrated_stroke/modules/dashboard/widgets/enhanced_home_tab.dart';

/// ===============================================================
/// DASHBOARD SCREEN
/// ===============================================================
/// - memakai CustomNavbar pill style
/// - Tab Profile menampilkan avatar user
/// - SOS tidak di navbar, tetapi ada pada Home
/// - Card Home: profile + detak jantung realtime dijadikan 1
/// - Ada edukasi stroke (FAST)
/// ===============================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;

  int _currentIndex = 0;
  String? _photoUrl;

  final List<Widget> _pages = [
    const EnhancedHomeTab(),
    const CommunityScreen(),
    const PatientChatDashboardScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadPhotoForNavbar();
  }

  /// untuk navbar -> profile icon pakai foto
  Future<void> _loadPhotoForNavbar() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await _supabase
          .from('users')
          .select('photo_url')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted || data == null) return;
      setState(() => _photoUrl = data['photo_url']?.toString());
    } catch (_) {}
  }

  void _onNavTap(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingNavbar(
      currentIndex: _currentIndex,
      onTap: _onNavTap,
      photoUrl: _photoUrl,
      onSosTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const EmergencyLocationScreen(),
          ),
        );
      },
      body: SafeArea(child: _pages[_currentIndex]),
    );
  }
}

/// ===============================================================
/// HOME TAB (Realtime Heart Rate + Profile Card)
/// ===============================================================
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

  String _userName = 'Integrated Stroke';
  String? _photoUrl;

  _DashboardStats _currentStats = _DashboardStats.empty();

  @override
  void initState() {
    super.initState();
    _statsController = StreamController<_DashboardStats>.broadcast();
    _statsStream = _statsController.stream;
    _init();
  }

  Future<void> _init() async {
    _userId = _supabase.auth.currentUser?.id;
    if (_userId == null) return;

    await _loadUserProfile();
    await _fetchLatestHeartRate();
    _listenRealtime();
  }

  void _listenRealtime() {
    if (_userId == null) return;

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
          final row = payload.newRecord;
          if (row['heart_rate'] != null) {
            _updateStats(heartRate: '${row['heart_rate']} bpm');
          }
        },
      )
      ..subscribe();
  }

  Future<void> _loadUserProfile() async {
    if (_userId == null) return;

    try {
      final data = await _supabase
          .from('users')
          .select('full_name, photo_url')
          .eq('id', _userId!)
          .maybeSingle();

      if (!mounted || data == null) return;

      setState(() {
        final name = data['full_name']?.toString() ?? '';
        _userName = name.isNotEmpty ? name : 'Integrated Stroke';
        _photoUrl = data['photo_url']?.toString();
      });
    } catch (_) {}
  }

  Future<void> _fetchLatestHeartRate() async {
    if (_userId == null) return;

    try {
      final response = await _supabase
          .from('sensor_data')
          .select('heart_rate')
          .eq('user_id', _userId!)
          .order('timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      final hr = response?['heart_rate'];
      if (hr != null) _updateStats(heartRate: '$hr bpm');
    } catch (_) {}
  }

  void _updateStats({String? heartRate}) {
    _currentStats = _DashboardStats(
      heartRate: heartRate ?? _currentStats.heartRate,
    );
    _statsController.add(_currentStats);
  }

  @override
  void dispose() {
    _sensorChannel?.unsubscribe();
    if (_sensorChannel != null) _supabase.removeChannel(_sensorChannel!);
    _statsController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 90;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottom),
      children: [
        StreamBuilder<_DashboardStats>(
          stream: _statsStream,
          builder: (context, snapshot) {
            final stats = snapshot.data ?? _DashboardStats.empty();
            final bpm = _parseHeartRate(stats.heartRate);

            return _ProfileHeartRateCard(
              name: _userName,
              photoUrl: _photoUrl,
              heartRate: stats.heartRate,
              status: _heartRateStatus(bpm),
            );
          },
        ),

        const SizedBox(height: 16),

        /// edukasi stroke
        const _SectionTitle('Edukasi Stroke'),
        const SizedBox(height: 10),
        const _StrokeEducationCard(),

        const SizedBox(height: 18),

        /// SOS dimasukkan Home (bukan navbar)
        const _SectionTitle('Akses Cepat'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickActionChip(
                icon: Icons.sos_rounded,
                label: 'SOS',
                color: Colors.redAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmergencyLocationScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionChip(
                icon: Icons.chat_bubble_outline,
                label: 'Chat Apoteker',
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientChatDashboardScreen()),
                ),
              ),
            ),
          ],
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
          childAspectRatio: 1.08,
          children: [
            _FeatureCardV2(
              icon: Icons.medication,
              label: 'Pengingat Obat',
              desc: 'Atur jadwal minum obat',
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedicationReminderScreen()),
              ),
            ),
            _FeatureCardV2(
              icon: Icons.fitness_center,
              label: 'Latihan',
              desc: 'Rehabilitasi harian',
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExerciseScreen()),
              ),
            ),
            _FeatureCardV2(
              icon: Icons.groups,
              label: 'Komunitas',
              desc: 'Diskusi & dukungan',
              color: Colors.deepOrange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CommunityScreen()),
              ),
            ),
            _FeatureCardV2(
              icon: Icons.chat,
              label: 'Konsultasi',
              desc: 'Chat dengan apoteker',
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PatientChatDashboardScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  int? _parseHeartRate(String hrText) {
    final m = RegExp(r'(\d+)').firstMatch(hrText);
    if (m == null) return null;
    return int.tryParse(m.group(1) ?? '');
  }

  String _heartRateStatus(int? bpm) {
    if (bpm == null) return 'Belum ada data';
    if (bpm < 60) return 'Rendah';
    if (bpm <= 100) return 'Normal';
    return 'Tinggi';
  }
}

/// ======================
/// MODEL
/// ======================
class _DashboardStats {
  final String heartRate;
  const _DashboardStats({required this.heartRate});
  factory _DashboardStats.empty() => const _DashboardStats(heartRate: '—');
}

/// ======================
/// UI COMPONENTS
/// ======================

class _ProfileHeartRateCard extends StatelessWidget {
  const _ProfileHeartRateCard({
    required this.name,
    required this.photoUrl,
    required this.heartRate,
    required this.status,
  });

  final String name;
  final String? photoUrl;
  final String heartRate;
  final String status;

  String get _initial => name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'I';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.92),
            Colors.teal.withOpacity(0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.92),
            backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                ? NetworkImage(photoUrl!)
                : null,
            child: (photoUrl == null || photoUrl!.isEmpty)
                ? Text(
              _initial,
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.monitor_heart, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      heartRate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StrokeEducationCard extends StatelessWidget {
  const _StrokeEducationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.health_and_safety, color: Colors.redAccent),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Apa itu Stroke?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Stroke adalah kondisi saat aliran darah ke otak terganggu (sumbatan/pecah pembuluh). '
                'Penanganan cepat dapat mencegah kerusakan otak permanen.',
            style: TextStyle(color: Colors.grey[700], height: 1.35),
          ),
          const SizedBox(height: 12),
          const Text('Kenali tanda FAST:', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _fastItem('F', 'Face drooping: wajah mencong'),
          _fastItem('A', 'Arm weakness: lengan melemah'),
          _fastItem('S', 'Speech difficulty: bicara pelo'),
          _fastItem('T', 'Time: segera cari bantuan medis'),
        ],
      ),
    );
  }

  static Widget _fastItem(String key, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                key,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.teal,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[800]))),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _FeatureCardV2 extends StatelessWidget {
  const _FeatureCardV2({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.95), color.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.20),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
