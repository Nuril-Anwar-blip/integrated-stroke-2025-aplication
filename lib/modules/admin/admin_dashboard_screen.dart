import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/widget/splash_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _manualTokenController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  RealtimeChannel? _channel;

  bool _loading = true;
  String? _generatedToken;
  List<Map<String, dynamic>> _pendingTokens = [];
  List<Map<String, dynamic>> _pharmacists = [];
  List<Map<String, dynamic>> _patients = [];
  int _activeChatRooms = 0;
  int _totalReminders = 0;
  List<Map<String, dynamic>> _latestChats = [];
  bool _isAdmin = false;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
    _setupRealtime();
  }

  @override
  void dispose() {
    _manualTokenController.dispose();
    _searchController.dispose();
    if (_channel != null) _supabase.removeChannel(_channel!);
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid != null) {
        final exists = await _supabase
            .from('admins')
            .select('user_id')
            .eq('user_id', uid)
            .limit(1);
        _isAdmin = exists is List && exists.isNotEmpty;
      } else {
        _isAdmin = false;
      }
      final tokens = await _supabase
          .from('pharmacist_invitations')
          .select('id, code, is_used, created_at')
          .eq('is_used', false)
          .order('created_at', ascending: false);
      // Gunakan filter 'or' agar kompatibel dengan variasi nilai role
      final pharm = await _supabase
          .from('users')
          .select('id, full_name, email, photo_url')
          .or(
            'role.eq.apoteker,role.eq.Apoteker,role.eq.pharmacist,role.eq.Pharmacist',
          )
          .order('full_name');
      final pats = await _supabase
          .from('users')
          .select('id, full_name, email, photo_url')
          .or('role.eq.pasien,role.eq.Pasien,role.eq.patient,role.eq.Patient')
          .order('full_name');
      final rooms = await _supabase.from('chat_rooms').select('id');
      final reminders = await _supabase
          .from('medication_reminders')
          .select('id');

      _pendingTokens = List<Map<String, dynamic>>.from(
        tokens.map((e) => Map<String, dynamic>.from(e as Map)),
      );
      _pharmacists = List<Map<String, dynamic>>.from(
        pharm.map((e) => Map<String, dynamic>.from(e as Map)),
      );
      _patients = List<Map<String, dynamic>>.from(
        pats.map((e) => Map<String, dynamic>.from(e as Map)),
      );
      _activeChatRooms = (rooms as List).length;
      _totalReminders = (reminders as List).length;
      await _loadLatestChats();
      _errorMessage = null;
    } catch (e) {
      _errorMessage =
          'Tidak bisa memuat data admin. Periksa akses admin dan kebijakan RLS.';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _setupRealtime() {
    _channel = _supabase.channel('admin_dashboard')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'pharmacist_invitations',
        callback: (_) => _loadAll(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'users',
        callback: (_) => _loadAll(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chat_rooms',
        callback: (_) => _loadAll(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'medication_reminders',
        callback: (_) => _loadAll(),
      )
      ..subscribe();
  }

  String _randomToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().millisecondsSinceEpoch;
    final seed = now % 1000000;
    final buf = StringBuffer();
    for (int i = 0; i < 8; i++) {
      final idx = (seed + i * 31) % chars.length;
      buf.write(chars[idx]);
    }
    return buf.toString();
  }

  Future<void> _createToken({String? manual}) async {
    String token = (manual != null && manual.trim().isNotEmpty)
        ? manual.trim()
        : _randomToken();
    if (manual == null || manual.trim().isEmpty) {
      for (int i = 0; i < 5; i++) {
        final exists = await _tokenExists(token);
        if (!exists) break;
        token = _randomToken();
      }
    }
    try {
      await _supabase.from('pharmacist_invitations').insert({
        'code': token,
        'is_used': false,
      });
      setState(() => _generatedToken = token);
      await _loadAll();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Token apoteker dibuat')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuat token: $e')));
    }
  }

  Future<bool> _tokenExists(String token) async {
    try {
      final byCode = await _supabase
          .from('pharmacist_invitations')
          .select('id')
          .eq('code', token)
          .limit(1);
      if (byCode is List && byCode.isNotEmpty) return true;
      final byToken = await _supabase
          .from('pharmacist_invitations')
          .select('id')
          .eq('token', token)
          .limit(1);
      if (byToken is List && byToken.isNotEmpty) return true;
    } catch (_) {}
    return false;
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Disalin ke clipboard')));
  }

  Future<void> _revokeToken(dynamic id) async {
    try {
      await _supabase
          .from('pharmacist_invitations')
          .update({'is_used': true})
          .eq('id', id);
      await _loadAll();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Token dicabut')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mencabut token: $e')));
    }
  }

  Future<void> _loadLatestChats() async {
    try {
      final List<dynamic> rows = await _supabase
          .from('chat_rooms')
          .select('id, patient_id, pharmacist_id, created_at')
          .order('created_at', ascending: false)
          .limit(10);
      final pIds = rows
          .map((e) => e['patient_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      final fIds = rows
          .map((e) => e['pharmacist_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      final roomIds =
          rows.map((e) => e['id']?.toString()).whereType<String>().toList();
      final ids = {...pIds, ...fIds}.toList();
      Map<String, Map<String, dynamic>> profiles = {};
      if (ids.isNotEmpty) {
        final List<dynamic> profs = await _supabase
            .from('users')
            .select('id, full_name, photo_url')
            .filter('id', 'in', ids);
        for (final raw in profs) {
          final m = Map<String, dynamic>.from(raw as Map);
          final id = m['id']?.toString();
          if (id != null) profiles[id] = m;
        }
      }

      Map<String, Map<String, dynamic>> lastMessages = {};
      if (roomIds.isNotEmpty) {
        final List<dynamic> msgs = await _supabase
            .from('messages')
            .select('room_id, content, created_at')
            .filter('room_id', 'in', roomIds)
            .order('created_at', ascending: false)
            .limit(50);
        for (final raw in msgs) {
          final m = Map<String, dynamic>.from(raw as Map);
          final rid = m['room_id']?.toString();
          if (rid == null || lastMessages.containsKey(rid)) continue;
          lastMessages[rid] = m;
        }
      }

      _latestChats = rows.map((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        final rid = m['id']?.toString() ?? '';
        final pid = m['patient_id']?.toString() ?? '';
        final fid = m['pharmacist_id']?.toString() ?? '';
        final lm = lastMessages[rid];
        final msg = lm?['content']?.toString() ?? 'Belum ada pesan';
        final time = lm?['created_at']?.toString();
        return {
          'id': rid,
          'patient_name': profiles[pid]?['full_name']?.toString() ?? 'Pasien',
          'pharmacist_name':
              profiles[fid]?['full_name']?.toString() ?? 'Apoteker',
          'last_message': msg,
          'last_time': time,
        };
      }).toList();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final filteredPharmacists = _filterUsers(_pharmacists);
    final filteredPatients = _filterUsers(_patients);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            onPressed: () => _loadAll(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Cari',
            onPressed: _openSearch,
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isAdmin || _errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage ??
                            'Akun ini tidak memiliki hak akses admin.',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadAll,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Apoteker',
                    value: _pharmacists.length.toString(),
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Pasien',
                    value: _patients.length.toString(),
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Chat Aktif',
                    value: _activeChatRooms.toString(),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Pengingat Obat',
                    value: _totalReminders.toString(),
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buat Token Apoteker',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _createToken(),
                          child: const Text('Buat Token Otomatis'),
                        ),
                      ],
                    ),
                    if (_generatedToken != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: Text('Token: ${_generatedToken!}')),
                          IconButton(
                            onPressed: () => _copy(_generatedToken!),
                            icon: const Icon(Icons.copy),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Token Belum Terpakai',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (_pendingTokens.isEmpty)
                      const Text('Tidak ada token aktif.')
                    else
                      ..._pendingTokens.map(
                        (t) => ListTile(
                          title: Text(t['code']?.toString() ?? '-'),
                          subtitle: Text('ID: ${t['id']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    _copy(t['code']?.toString() ?? ''),
                                icon: const Icon(Icons.copy),
                              ),
                              IconButton(
                                onPressed: () => _revokeToken(t['id']),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chat Terakhir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_latestChats.isEmpty)
                      const Text('Belum ada data.')
                    else
                      ..._latestChats.map(
                        (c) => ListTile(
                          title: Text(
                            '${c['patient_name']} ↔ ${c['pharmacist_name']}',
                          ),
                          subtitle: Text(
                            'Room: ${c['id']} • ${c['last_message']}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: c['last_time'] != null
                              ? Text(
                                  DateFormat('d MMM HH:mm').format(
                                    DateTime.tryParse(
                                          c['last_time']?.toString() ?? '',
                                        ) ??
                                        DateTime.now(),
                                  ),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Apoteker',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_pharmacists.isEmpty)
                      const Text('Tidak ada apoteker.')
                    else
                      ...filteredPharmacists.map(
                        (u) => ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                (u['photo_url']?.toString().isNotEmpty ?? false)
                                ? NetworkImage(u['photo_url']?.toString() ?? '')
                                : null,
                            child: (u['photo_url']?.toString().isEmpty ?? true)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(u['full_name']?.toString() ?? '-'),
                          subtitle: Text(u['email']?.toString() ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _confirmDeleteUser(u['id']?.toString(), 'apoteker'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pasien',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_patients.isEmpty)
                      const Text('Tidak ada pasien.')
                    else
                      ...filteredPatients.map(
                        (u) => ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                (u['photo_url']?.toString().isNotEmpty ?? false)
                                ? NetworkImage(u['photo_url']?.toString() ?? '')
                                : null,
                            child: (u['photo_url']?.toString().isEmpty ?? true)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(u['full_name']?.toString() ?? '-'),
                          subtitle: Text(u['email']?.toString() ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _confirmDeleteUser(u['id']?.toString(), 'pasien'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterUsers(List<Map<String, dynamic>> source) {
    if (_searchQuery.trim().isEmpty) return source;
    final q = _searchQuery.toLowerCase();
    return source.where((u) {
      final name = u['full_name']?.toString().toLowerCase() ?? '';
      final email = u['email']?.toString().toLowerCase() ?? '';
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  void _openSearch() {
    _searchController.text = _searchQuery;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cari pengguna'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Nama atau email',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (_) => _applySearch(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              _applySearch(clear: true);
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () {
              _applySearch();
              Navigator.pop(context);
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }

  void _applySearch({bool clear = false}) {
    setState(() {
      _searchQuery = clear ? '' : _searchController.text;
    });
  }

  Future<void> _confirmDeleteUser(String? id, String label) async {
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus pengguna'),
        content: Text('Hapus $label ini secara permanen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _deleteUser(id);
    }
  }

  Future<void> _deleteUser(String id) async {
    try {
      await _supabase.from('users').delete().eq('id', id);
      await _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengguna dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
