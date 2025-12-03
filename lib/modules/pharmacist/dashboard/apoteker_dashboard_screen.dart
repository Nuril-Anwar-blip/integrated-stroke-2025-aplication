import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/login_screen.dart';
import '../../consultation/consultation_screen.dart';

class PharmacistConversation {
  PharmacistConversation({
    required this.roomId,
    required this.patientId,
    required this.patientName,
    required this.patientAvatar,
    this.lastMessage,
    this.lastMessageAt,
  });

  final String roomId;
  final String patientId;
  final String patientName;
  final String patientAvatar;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  factory PharmacistConversation.fromRpc(Map<String, dynamic> map) {
    return PharmacistConversation(
      roomId: map['room_id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      patientName: map['patient_full_name']?.toString() ?? 'Pasien',
      patientAvatar: map['patient_photo_url']?.toString() ?? '',
      lastMessage: map['last_message_content']?.toString(),
      lastMessageAt: map['last_message_created_at'] != null
          ? DateTime.parse(map['last_message_created_at'])
          : null,
    );
  }
}

class ApotekerDashboardScreen extends StatefulWidget {
  const ApotekerDashboardScreen({super.key});

  @override
  State<ApotekerDashboardScreen> createState() =>
      _ApotekerDashboardScreenState();
}

class _ApotekerDashboardScreenState extends State<ApotekerDashboardScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  final List<PharmacistConversation> _rooms = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  RealtimeChannel? _realtimeChannel;
  Timer? _debounce;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = _supabase.auth.currentUser?.id;
    _searchController.addListener(() => setState(() {}));
    _loadRooms();
    _setupRealtime();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  Future<void> _loadRooms({bool showSpinner = true}) async {
    if (_userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sesi berakhir. Silakan login kembali.';
      });
      return;
    }
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final conversations = await _fetchConversations();
      if (!mounted) return;
      setState(() {
        _rooms
          ..clear()
          ..addAll(conversations);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat percakapan. Tarik untuk menyegarkan.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa memuat percakapan: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<List<PharmacistConversation>> _fetchConversations() async {
    if (_userId == null) return [];

    final List<dynamic> rooms = await _supabase
        .from('chat_rooms')
        .select(
          'id, patient_id, created_at, patient:patient_id (id, full_name, photo_url)',
        )
        .eq('pharmacist_id', _userId!)
        .order('created_at', ascending: false);

    final roomIds = rooms
        .map((room) => room['id']?.toString())
        .whereType<String>()
        .toList();
    final patientIds = rooms
        .map((room) => room['patient_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    final latestMessages = await _fetchLatestMessages(roomIds);
    final fallbackProfiles = await _fetchPatientProfiles(patientIds);

    final conversations = rooms.map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      final roomId = row['id']?.toString() ?? '';
      final patientId = row['patient_id']?.toString() ?? '';
      final patient = Map<String, dynamic>.from(
        (row['patient'] as Map?) ??
            (fallbackProfiles[patientId] ?? <String, dynamic>{}),
      );
      final latestMessage = latestMessages[roomId];
      return PharmacistConversation(
        roomId: roomId,
        patientId: patientId,
        patientName: patient['full_name']?.toString() ?? 'Pasien',
        patientAvatar: patient['photo_url']?.toString() ?? '',
        lastMessage: latestMessage?['content']?.toString(),
        lastMessageAt: latestMessage?['created_at'] != null
            ? DateTime.parse(latestMessage!['created_at'] as String)
            : null,
      );
    }).toList();

    conversations.sort((a, b) {
      final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return conversations;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchLatestMessages(
    List<String> roomIds,
  ) async {
    if (roomIds.isEmpty) return {};
    // Ambil pesan terbaru untuk setiap room menggunakan filter 'in' pada room_id
    final List<dynamic> rows = await _supabase
        .from('messages')
        .select('room_id, content, created_at')
        .filter('room_id', 'in', roomIds)
        .order('created_at', ascending: false);

    final latest = <String, Map<String, dynamic>>{};
    for (final raw in rows) {
      final map = Map<String, dynamic>.from(raw as Map);
      final roomId = map['room_id']?.toString();
      if (roomId == null || latest.containsKey(roomId)) continue;
      latest[roomId] = map;
    }
    return latest;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchPatientProfiles(
    List<String> patientIds,
  ) async {
    if (patientIds.isEmpty) return {};
    final inValue = _toInFilter(patientIds);
    final List<dynamic> patients = await _supabase
        .from('users')
        .select('id, full_name, photo_url')
        .filter('id', 'in', inValue)
        .order('full_name');
    final map = <String, Map<String, dynamic>>{};
    for (final raw in patients) {
      final m = Map<String, dynamic>.from(raw as Map);
      final id = m['id']?.toString();
      if (id != null) map[id] = m;
    }
    return map;
  }

  /// Bangun string filter IN PostgREST: ("id1","id2")
  String _toInFilter(List<String> values) {
    final quoted = values.map((e) => '"$e"').join(',');
    return '($quoted)';
  }

  void _setupRealtime() {
    if (_userId == null) return;
    _realtimeChannel = _realtimeChannel =
        _supabase.channel('pharmacist_chat_dashboard_${_userId!}')
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'chat_rooms',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'pharmacist_id',
              value: _userId!,
            ),
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

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadRooms(showSpinner: false);
    });
  }

  List<PharmacistConversation> get _filteredRooms {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _rooms;
    return _rooms
        .where((room) => room.patientName.toLowerCase().contains(query))
        .toList();
  }

  String _formatTimestamp(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    if (today == messageDate) {
      return DateFormat.Hm().format(time.toLocal());
    }
    return DateFormat('dd MMM', 'id_ID').format(time.toLocal());
  }

  Future<void> _openConversation(PharmacistConversation convo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultationScreen(
          roomId: convo.roomId,
          recipientId: convo.patientId,
          recipientName: convo.patientName,
        ),
      ),
    );
    if (mounted) _loadRooms(showSpinner: false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Dashboard Apoteker',
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
                : () => _loadRooms(showSpinner: false),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadRooms(showSpinner: false),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  _PharmacistHeroCard(totalRooms: _rooms.length),
                  const SizedBox(height: 16),
                  _SearchField(controller: _searchController),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(
                      message: _errorMessage!,
                      onRetry: () => _loadRooms(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_filteredRooms.isEmpty)
                    const _PharmacistEmptyState()
                  else
                    ..._filteredRooms.map(
                      (room) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ConversationTile(
                          conversation: room,
                          timeLabel: _formatTimestamp(room.lastMessageAt),
                          onTap: () => _openConversation(room),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _PharmacistHeroCard extends StatelessWidget {
  const _PharmacistHeroCard({required this.totalRooms});

  final int totalRooms;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Colors.orange.shade500, Colors.deepOrange.shade300],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.shade100,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pasien membutuhkan Anda',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalRooms == 0
                ? 'Belum ada sesi aktif.\nTunggu pasien memulai percakapan.'
                : '$totalRooms percakapan aktif perlu dipantau.',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Cari nama pasien',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.timeLabel,
    required this.onTap,
  });

  final PharmacistConversation conversation;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: conversation.patientAvatar.isNotEmpty
              ? NetworkImage(conversation.patientAvatar)
              : null,
          child: conversation.patientAvatar.isEmpty
              ? const Icon(Icons.person_outline)
              : null,
        ),
        title: Text(
          conversation.patientName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          conversation.lastMessage ?? 'Belum ada pesan',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeLabel,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _PharmacistEmptyState extends StatelessWidget {
  const _PharmacistEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.chat_outlined,
            size: 48,
            color: Colors.deepOrange.shade300,
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada percakapan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pasien akan muncul secara otomatis ketika mereka memulai konsultasi.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Text(message, style: const TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
