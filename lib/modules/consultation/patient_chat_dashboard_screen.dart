import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'consultation_screen.dart';
// import '../auth/login_screen.dart';

class ChatRoomInfo {
  const ChatRoomInfo({
    required this.roomId,
    required this.pharmacistId,
    required this.pharmacistName,
    required this.pharmacistAvatarUrl,
    this.lastMessage,
    this.lastMessageTimestamp,
  });

  factory ChatRoomInfo.fromMap(Map<String, dynamic> map) {
    return ChatRoomInfo(
      roomId: map['room_id']?.toString() ?? '',
      pharmacistId: map['pharmacist_id']?.toString() ?? '',
      pharmacistName: map['pharmacist_full_name'] ?? 'Apoteker',
      pharmacistAvatarUrl: map['pharmacist_photo_url'] ?? '',
      lastMessage: map['last_message_content'],
      lastMessageTimestamp: map['last_message_created_at'] != null
          ? DateTime.parse(map['last_message_created_at'])
          : null,
    );
  }

  final String roomId;
  final String pharmacistId;
  final String pharmacistName;
  final String pharmacistAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
}

class PatientChatDashboardScreen extends StatefulWidget {
  const PatientChatDashboardScreen({super.key});

  @override
  State<PatientChatDashboardScreen> createState() =>
      _PatientChatDashboardScreenState();
}

class _PatientChatDashboardScreenState
    extends State<PatientChatDashboardScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final List<ChatRoomInfo> _rooms = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  RealtimeChannel? _realtimeChannel;
  Timer? _refreshDebounce;
  bool _isStartingChat = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
    _setupRealtime();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshDebounce?.cancel();
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  Future<void> _loadRooms({bool showSpinner = true}) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sesi Anda sudah berakhir. Silakan login ulang.';
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
      final mapped = await _fetchPatientRooms(currentUser.id);
      if (!mounted) return;
      setState(() {
        _rooms
          ..clear()
          ..addAll(mapped);
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Gagal memuat percakapan. Tarik ke bawah untuk refresh.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa memuat daftar chat: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<List<ChatRoomInfo>> _fetchPatientRooms(String userId) async {
    try {
      final List<dynamic> rows = await _supabase
          .from('chat_rooms')
          .select('id, pharmacist_id, created_at')
          .eq('patient_id', userId)
          .order('created_at', ascending: false);

      final roomIds = rows
          .map((e) => e['id']?.toString())
          .whereType<String>()
          .toList();
      final pharmacistIds = rows
          .map((e) => e['pharmacist_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      final pharmacistProfiles = <String, Map<String, dynamic>>{};
      if (pharmacistIds.isNotEmpty) {
        final List<dynamic> pharmacists = await _supabase
            .from('users')
            .select('id, full_name, photo_url')
            .filter('id', 'in', pharmacistIds);
        for (final raw in pharmacists) {
          final map = Map<String, dynamic>.from(raw as Map);
          final id = map['id']?.toString();
          if (id != null) pharmacistProfiles[id] = map;
        }
      }

      final latestMessages = await _fetchLatestMessages(roomIds);

      final mapped = rows.map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        final roomId = row['id']?.toString() ?? '';
        final pharmacistId = row['pharmacist_id']?.toString() ?? '';
        final pharmacist = pharmacistProfiles[pharmacistId] ?? {};
        final latestMessage = latestMessages[roomId];
        return ChatRoomInfo(
          roomId: roomId,
          pharmacistId: pharmacistId,
          pharmacistName: pharmacist['full_name']?.toString() ?? 'Apoteker',
          pharmacistAvatarUrl: pharmacist['photo_url']?.toString() ?? '',
          lastMessage: latestMessage?['content']?.toString(),
          lastMessageTimestamp: latestMessage?['created_at'] != null
              ? DateTime.parse(latestMessage!['created_at'] as String)
              : null,
        );
      }).toList();

      mapped.sort((a, b) {
        final aTime =
            a.lastMessageTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.lastMessageTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return mapped;
    } on PostgrestException catch (e) {
      throw Exception('Tidak bisa memuat daftar chat: ${e.message}');
    }
  }

  Future<Map<String, Map<String, dynamic>>> _fetchLatestMessages(
    List<String> roomIds,
  ) async {
    if (roomIds.isEmpty) return {};
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

  void _setupRealtime() {
    _realtimeChannel = _supabase.channel('patient_chat_dashboard_channel')
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

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadRooms(showSpinner: false);
    });
  }

  List<ChatRoomInfo> get _filteredRooms {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _rooms;
    return _rooms
        .where((room) => room.pharmacistName.toLowerCase().contains(query))
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

  Future<void> _openRoom(ChatRoomInfo room) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultationScreen(
          roomId: room.roomId,
          recipientId: room.pharmacistId,
          recipientName: room.pharmacistName,
        ),
      ),
    );
    if (mounted) _loadRooms(showSpinner: false);
  }

  Future<List<_PharmacistSummary>> _fetchPharmacists() async {
    final roles = ['apoteker', 'Apoteker', 'pharmacist', 'Pharmacist'];
    final rows = await _supabase
        .from('users')
        .select('id, full_name, photo_url')
        .filter('role', 'in', roles)
        .order('full_name');
    return rows
        .map<_PharmacistSummary>(
          (row) => _PharmacistSummary(
            id: row['id']?.toString() ?? '',
            name: row['full_name']?.toString() ?? 'Apoteker',
            avatarUrl: row['photo_url']?.toString() ?? '',
          ),
        )
        .where((summary) => summary.id.isNotEmpty)
        .toList();
  }

  Future<void> _showPharmacistPicker() async {
    if (_isStartingChat) return;
    setState(() => _isStartingChat = true);
    try {
      final pharmacists = await _fetchPharmacists();
      if (!mounted) return;
      if (pharmacists.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada apoteker yang tersedia.')),
        );
        return;
      }
      final selected = await showModalBottomSheet<_PharmacistSummary>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => _PharmacistPickerSheet(pharmacists: pharmacists),
      );
      if (selected != null) {
        await _startChatWithPharmacist(selected);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar apoteker: $e')),
      );
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  Future<void> _startChatWithPharmacist(_PharmacistSummary pharmacist) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Sesi berakhir, silakan login ulang.');
      }

      final existing = await _supabase
          .from('chat_rooms')
          .select('id')
          .eq('patient_id', currentUser.id)
          .eq('pharmacist_id', pharmacist.id)
          .maybeSingle();

      final roomId = existing != null
          ? (existing['id']?.toString() ?? '')
          : ((await _supabase
                    .from('chat_rooms')
                    .insert({
                      'patient_id': currentUser.id,
                      'pharmacist_id': pharmacist.id,
                    })
                    .select('id')
                    .single())['id'])
                .toString();

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConsultationScreen(
            roomId: roomId,
            recipientId: pharmacist.id,
            recipientName: pharmacist.name,
          ),
        ),
      );
      if (mounted) _loadRooms(showSpinner: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memulai konsultasi: $e')));
    }
  }

  // Logout dihapus sesuai permintaan

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Konsultasi Saya',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isStartingChat ? null : _showPharmacistPicker,
        backgroundColor: Colors.teal.shade600,
        icon: Icon(
          _isStartingChat ? Icons.hourglass_top : Icons.add_comment_rounded,
        ),
        label: Text(_isStartingChat ? 'Menghubungkan...' : 'Cari Apoteker'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadRooms(showSpinner: false),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  _PatientHeroCard(totalRooms: _rooms.length),
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
                    _EmptyState(onCreateTap: _showPharmacistPicker)
                  else
                    ..._filteredRooms.map(
                      (room) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChatRoomCard(
                          info: room,
                          subtitle: room.lastMessage ?? 'Belum ada pesan',
                          timeLabel: _formatTimestamp(
                            room.lastMessageTimestamp,
                          ),
                          onTap: () => _openRoom(room),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _PatientHeroCard extends StatelessWidget {
  const _PatientHeroCard({required this.totalRooms});
  final int totalRooms;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Colors.teal.shade500, Colors.teal.shade300],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade100,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Terhubung dengan Apoteker',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalRooms == 0
                ? 'Belum ada sesi. Mulai konsultasi sekarang.'
                : '$totalRooms sesi aktif siap membantu Anda.',
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
        hintText: 'Cari nama apoteker',
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

class _ChatRoomCard extends StatelessWidget {
  const _ChatRoomCard({
    required this.info,
    required this.subtitle,
    required this.timeLabel,
    required this.onTap,
  });

  final ChatRoomInfo info;
  final String subtitle;
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
          backgroundImage: info.pharmacistAvatarUrl.isNotEmpty
              ? NetworkImage(info.pharmacistAvatarUrl)
              : null,
          child: info.pharmacistAvatarUrl.isEmpty
              ? const Icon(Icons.person_outline)
              : null,
        ),
        title: Text(
          info.pharmacistName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTap});
  final VoidCallback onCreateTap;

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
          Icon(Icons.chat_outlined, size: 48, color: Colors.teal.shade400),
          const SizedBox(height: 12),
          const Text(
            'Belum ada percakapan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mulai konsultasi pertama Anda dan dapatkan jawaban langsung dari apoteker.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onCreateTap,
            child: const Text('Mulai Konsultasi'),
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

class _PharmacistSummary {
  const _PharmacistSummary({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String avatarUrl;
}

class _PharmacistPickerSheet extends StatefulWidget {
  const _PharmacistPickerSheet({required this.pharmacists});

  final List<_PharmacistSummary> pharmacists;

  @override
  State<_PharmacistPickerSheet> createState() => _PharmacistPickerSheetState();
}

class _PharmacistPickerSheetState extends State<_PharmacistPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.pharmacists
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const Text(
                'Pilih Apoteker',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cari nama apoteker',
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Tidak ada apoteker dengan nama tersebut.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final pharmacist = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: pharmacist.avatarUrl.isNotEmpty
                              ? NetworkImage(pharmacist.avatarUrl)
                              : null,
                          child: pharmacist.avatarUrl.isEmpty
                              ? const Icon(Icons.person_outline)
                              : null,
                        ),
                        title: Text(pharmacist.name),
                        subtitle: const Text('Siap membantu'),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                        ),
                        onTap: () => Navigator.pop(context, pharmacist),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: filtered.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
