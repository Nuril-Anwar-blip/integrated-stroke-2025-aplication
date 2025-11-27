import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../consultation/consultation_screen.dart';
import '../medication_reminder/medication_history_screen.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  int _totalPharmacists = 0;
  int _totalPatients = 0;
  int _totalRooms = 0;

  List<_PharmacistInfo> _pharmacists = [];
  List<_PatientInfo> _patients = [];

  late final TabController _tabController;
  RealtimeChannel? _realtimeChannel;
  Timer? _refreshDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
    _setupRealtime();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshDebounce?.cancel();
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadAll(showSpinner: false);
    });
  }

  void _setupRealtime() {
    _realtimeChannel = _supabase.channel('admin_dashboard')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'users',
        callback: (_) => _scheduleRefresh(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chat_rooms',
        callback: (_) => _scheduleRefresh(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        callback: (_) => _scheduleRefresh(),
      )
      ..subscribe();
  }

  Future<void> _loadAll({bool showSpinner = true}) async {
    setState(() {
      _isRefreshing = showSpinner;
      if (_isLoading) _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _supabase
            .from('users')
            .select('id, full_name, photo_url')
            .eq('role', 'apoteker'),
        _supabase
            .from('users')
            .select('id, full_name, photo_url')
            .eq('role', 'pasien'),
        _supabase.from('chat_rooms').select('id, patient_id, pharmacist_id'),
      ]);

      final pharmacistRows = List<Map<String, dynamic>>.from(
        (results[0] as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      final patientRows = List<Map<String, dynamic>>.from(
        (results[1] as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      final roomRows = List<Map<String, dynamic>>.from(
        (results[2] as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );

      final pharmacistRoomCount = <String, int>{};
      final patientRoomCount = <String, int>{};
      for (final room in roomRows) {
        final pid = room['pharmacist_id']?.toString();
        final uid = room['patient_id']?.toString();
        if (pid != null) {
          pharmacistRoomCount[pid] = (pharmacistRoomCount[pid] ?? 0) + 1;
        }
        if (uid != null) {
          patientRoomCount[uid] = (patientRoomCount[uid] ?? 0) + 1;
        }
      }

      _pharmacists = pharmacistRows
          .map(
            (row) => _PharmacistInfo(
              id: row['id']?.toString() ?? '',
              name: row['full_name']?.toString() ?? 'Apoteker',
              avatarUrl: row['photo_url']?.toString() ?? '',
              roomCount: pharmacistRoomCount[row['id']?.toString()] ?? 0,
            ),
          )
          .where((p) => p.id.isNotEmpty)
          .toList();

      _patients = patientRows
          .map(
            (row) => _PatientInfo(
              id: row['id']?.toString() ?? '',
              name: row['full_name']?.toString() ?? 'Pasien',
              avatarUrl: row['photo_url']?.toString() ?? '',
              roomCount: patientRoomCount[row['id']?.toString()] ?? 0,
            ),
          )
          .where((p) => p.id.isNotEmpty)
          .toList();

      _totalPharmacists = _pharmacists.length;
      _totalPatients = _patients.length;
      _totalRooms = roomRows.length;

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = 'Gagal memuat data: $e';
      });
    }
  }

  Future<void> _openPharmacistRooms(_PharmacistInfo p) async {
    final List<dynamic> rooms = await _supabase
        .from('chat_rooms')
        .select('id, patient_id')
        .eq('pharmacist_id', p.id)
        .order('created_at', ascending: false);
    final List<Map<String, dynamic>> patients = await _supabase
        .from('users')
        .select('id, full_name')
        .contains(
          'id',
          rooms
              .map((e) => e['patient_id']?.toString())
              .whereType<String>()
              .toSet()
              .toList(),
        );
    final nameById = <String, String>{
      for (final raw in patients)
        if (raw['id'] != null)
          raw['id'].toString(): raw['full_name']?.toString() ?? 'Pasien',
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: p.avatarUrl.isNotEmpty
                          ? NetworkImage(p.avatarUrl)
                          : null,
                      child: p.avatarUrl.isEmpty
                          ? const Icon(Icons.local_pharmacy)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text('Total percakapan: ${rooms.length}'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final room in rooms)
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.chat)),
                      title: Text(
                        nameById[room['patient_id']?.toString()] ?? 'Pasien',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: const Text('Percakapan konsultasi'),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                      ),
                      onTap: () async {
                        final patientName =
                            nameById[room['patient_id']?.toString()] ??
                            'Pasien';
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConsultationScreen(
                              roomId: room['id']?.toString() ?? '',
                              recipientId: room['patient_id']?.toString() ?? '',
                              recipientName: patientName,
                            ),
                          ),
                        );
                        if (mounted) _loadAll(showSpinner: false);
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openPatientActions(_PatientInfo p) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Lihat riwayat pengingat obat'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MedicationHistoryScreen(userId: p.id),
                    ),
                  );
                  if (mounted) _loadAll(showSpinner: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Buka percakapan aktif'),
                subtitle: Text('${p.roomCount} percakapan'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final List<dynamic> rooms = await _supabase
                      .from('chat_rooms')
                      .select('id, pharmacist_id')
                      .eq('patient_id', p.id)
                      .order('created_at', ascending: false);
                  if (rooms.isEmpty) return;
                  final first = rooms.first as Map;
                  final pharmacist = await _supabase
                      .from('users')
                      .select('full_name')
                      .eq('id', first['pharmacist_id'])
                      .maybeSingle();
                  final pharmacistName = pharmacist == null
                      ? 'Apoteker'
                      : (pharmacist['full_name']?.toString() ?? 'Apoteker');
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConsultationScreen(
                        roomId: first['id']?.toString() ?? '',
                        recipientId: first['pharmacist_id']?.toString() ?? '',
                        recipientName: pharmacistName,
                      ),
                    ),
                  );
                  if (mounted) _loadAll(showSpinner: false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _generateInvitationCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _createAndShareInvitation() async {
    final code = _generateInvitationCode();
    try {
      await _supabase.from('pharmacist_invitations').insert({
        'code': code,
        'is_used': false,
        'created_by': _supabase.auth.currentUser?.id,
      });
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_pharmacy, color: Colors.teal),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Kode Registrasi Apoteker',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            code,
                            style: const TextStyle(
                              fontSize: 20,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: code));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kode disalin')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.share),
                          label: const Text('Bagikan'),
                          onPressed: () {
                            Share.share(
                              'Kode registrasi Apoteker: $code\nGunakan saat mendaftar di aplikasi Integrated Stroke.',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Kirim Email'),
                          onPressed: () async {
                            final uri = Uri(
                              scheme: 'mailto',
                              path: '',
                              query:
                                  'subject=Kode Registrasi Apoteker&body=Gunakan kode berikut saat mendaftar: $code',
                            );
                            await launchUrl(uri);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      final errorText = e.toString().toLowerCase();
      if (errorText.contains('permission denied') ||
          errorText.contains('rls')) {
        _showSetupDialog(
          title: 'Izin ditolak (RLS)',
          message:
              'Server menolak akses saat membuat kode. Pastikan kebijakan Row Level Security (RLS) mengizinkan admin untuk INSERT/SELECT/UPDATE pada tabel undangan, serta mengizinkan SELECT untuk pengguna belum login saat validasi kode registrasi.',
        );
      } else if (errorText.contains('relation') &&
          errorText.contains('does not exist')) {
        _showSetupDialog(
          title: 'Tabel tidak ditemukan',
          message:
              'Tabel pharmacist_invitations belum dibuat di Supabase. Buat tabel dan kebijakan RLS agar fitur undangan berfungsi.',
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat undangan: $e')));
      }
    }
  }

  void _showSetupDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 12),
              const Text('SQL yang disarankan:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SelectableText('''
CREATE TABLE public.pharmacist_invitations (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  code text UNIQUE NOT NULL,
  is_used boolean DEFAULT false NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.pharmacist_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin manage invitations" ON public.pharmacist_invitations
AS PERMISSIVE FOR ALL
USING (EXISTS (
  SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.role = 'admin'
))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.role = 'admin'
));

CREATE POLICY "Anyone can check unused code" ON public.pharmacist_invitations
FOR SELECT USING (is_used = false);

CREATE POLICY "Mark code used" ON public.pharmacist_invitations
FOR UPDATE USING (is_used = false) WITH CHECK (true);
'''),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Dashboard Admin',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            tooltip: 'Segarkan',
            onPressed: _isRefreshing
                ? null
                : () => _loadAll(showSpinner: false),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.teal.shade700,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.teal,
          tabs: const [
            Tab(icon: Icon(Icons.local_pharmacy), text: 'Apoteker'),
            Tab(icon: Icon(Icons.people_alt_rounded), text: 'Pasien'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAndShareInvitation,
        backgroundColor: Colors.teal.shade600,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Undang Apoteker'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildPharmacistTab(), _buildPatientTab()],
            ),
    );
  }

  Widget _buildHeaderStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Apoteker',
              value: _totalPharmacists.toString(),
              color: Colors.teal,
              icon: Icons.local_pharmacy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Pasien',
              value: _totalPatients.toString(),
              color: Colors.indigo,
              icon: Icons.people_alt_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Percakapan',
              value: _totalRooms.toString(),
              color: Colors.deepOrange,
              icon: Icons.chat_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacistTab() {
    return RefreshIndicator(
      onRefresh: () => _loadAll(showSpinner: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
        children: [
          _buildHeaderStats(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SectionTitle('Daftar Apoteker'),
          ),
          const SizedBox(height: 8),
          for (final p in _pharmacists)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: p.avatarUrl.isNotEmpty
                        ? NetworkImage(p.avatarUrl)
                        : null,
                    child: p.avatarUrl.isEmpty
                        ? const Icon(Icons.local_pharmacy)
                        : null,
                  ),
                  title: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${p.roomCount} percakapan aktif'),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () => _openPharmacistRooms(p),
                ),
              ),
            ),
          if (_pharmacists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Belum ada apoteker terdaftar')),
            ),
        ],
      ),
    );
  }

  Widget _buildPatientTab() {
    return RefreshIndicator(
      onRefresh: () => _loadAll(showSpinner: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
        children: [
          _buildHeaderStats(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SectionTitle('Daftar Pasien'),
          ),
          const SizedBox(height: 8),
          for (final p in _patients)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: p.avatarUrl.isNotEmpty
                        ? NetworkImage(p.avatarUrl)
                        : null,
                    child: p.avatarUrl.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${p.roomCount} percakapan konsultasi'),
                  trailing: PopupMenuButton<int>(
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 1,
                        child: Text('Riwayat obat'),
                      ),
                      const PopupMenuItem(
                        value: 2,
                        child: Text('Buka percakapan'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 1) {
                        _openPatientActions(p);
                      } else {
                        _openPatientActions(p);
                      }
                    },
                  ),
                  onTap: () => _openPatientActions(p),
                ),
              ),
            ),
          if (_patients.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Belum ada pasien terdaftar')),
            ),
        ],
      ),
    );
  }
}

class _PharmacistInfo {
  const _PharmacistInfo({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.roomCount,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final int roomCount;
}

class _PatientInfo {
  const _PatientInfo({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.roomCount,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final int roomCount;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
