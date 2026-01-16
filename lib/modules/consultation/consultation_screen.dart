import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool _isImageUrl(String url) {
  final lower = url.toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.contains('image');
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.createdAt,
    this.metadata,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'].toString(),
      content: map['content'] ?? '',
      senderId: map['sender_id'],
      createdAt: DateTime.parse(map['created_at']),
      // Metadata dari kolom jsonb untuk lampiran (gambar/dokumen)
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  final String id;
  final String content;
  final String senderId;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
}

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({
    super.key,
    required this.roomId,
    required this.recipientId,
    required this.recipientName,
  });

  final String roomId;
  final String recipientId;
  final String recipientName;

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final ValueNotifier<bool> _isSending = ValueNotifier<bool>(false);

  late final SupabaseClient _supabase;
  late final Stream<List<ChatMessage>> _messagesStream;
  String? _currentUserId;
  String? _recipientPhone;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _currentUserId = _supabase.auth.currentUser?.id;
    _messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomId)
        .order('created_at', ascending: true)
        .map(
          (rows) => rows
              .map((row) => ChatMessage.fromMap(row as Map<String, dynamic>))
              .toList(),
        );
    // Ambil nomor telepon penerima untuk fitur panggilan
    _loadRecipientPhone();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _isSending.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _textController.text.trim();
    if (content.isEmpty || _currentUserId == null) return;

    _isSending.value = true;
    try {
      await _supabase.from('messages').insert({
        'room_id': widget.roomId,
        'sender_id': _currentUserId,
        'content': content,
      });
      _textController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim pesan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isSending.value = false;
    }
  }

  // Ambil nomor telepon penerima dari tabel users
  Future<void> _loadRecipientPhone() async {
    try {
      final row = await _supabase
          .from('users')
          .select('phone_number')
          .eq('id', widget.recipientId)
          .maybeSingle();
      if (row != null) {
        setState(() => _recipientPhone = row['phone_number']?.toString());
      }
    } catch (_) {}
  }

  // Kirim lampiran gambar: unggah ke Storage dan simpan URL pada metadata pesan
  Future<void> _pickAndSendPhoto() async {
    if (_currentUserId == null) return;
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      _isSending.value = true;
      final file = File(picked.path);
      final ext = picked.name.split('.').last.toLowerCase();
      // Gunakan bucket khusus chat: 'chat_attachments'
      final bucket = 'chat_attachments';
      final objectPath =
          '${_currentUserId}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';

      await _supabase.storage.from(bucket).upload(objectPath, file);
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(objectPath);

      try {
        await _supabase.from('messages').insert({
          'room_id': widget.roomId,
          'sender_id': _currentUserId,
          'content': '',
          'metadata': {
            'type': 'image',
            'url': publicUrl,
            'name': picked.name,
            'size': await file.length(),
          },
        });
      } catch (_) {
        // Fallback bila kolom 'metadata' tidak ada: kirim URL sebagai content
        await _supabase.from('messages').insert({
          'room_id': widget.roomId,
          'sender_id': _currentUserId,
          'content': publicUrl,
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim foto: $e')));
    } finally {
      _isSending.value = false;
    }
  }

  // Kirim lampiran dokumen umum
  Future<void> _pickAndSendFile() async {
    if (_currentUserId == null) return;
    try {
      final result = await FilePicker.platform.pickFiles(withReadStream: false);
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      if (f.path == null) return;

      _isSending.value = true;
      final file = File(f.path!);
      final ext = (f.extension ?? 'bin').toLowerCase();
      // Gunakan bucket khusus chat: 'chat_attachments'
      final bucket = 'chat_attachments';
      final objectPath =
          '${_currentUserId}/${DateTime.now().millisecondsSinceEpoch}_${f.name}';

      await _supabase.storage.from(bucket).upload(objectPath, file);
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(objectPath);

      try {
        await _supabase.from('messages').insert({
          'room_id': widget.roomId,
          'sender_id': _currentUserId,
          'content': f.name,
          'metadata': {
            'type': 'file',
            'url': publicUrl,
            'name': f.name,
            'size': f.size,
            'ext': ext,
          },
        });
      } catch (_) {
        // Fallback bila kolom 'metadata' tidak ada: kirim nama + URL sebagai content
        await _supabase.from('messages').insert({
          'room_id': widget.roomId,
          'sender_id': _currentUserId,
          'content': '${f.name} | ${publicUrl}',
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim dokumen: $e')));
    } finally {
      _isSending.value = false;
    }
  }

  // Lakukan panggilan telepon menggunakan nomor penerima bila tersedia
  Future<void> _startPhoneCall() async {
    final phone = _recipientPhone?.trim();
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor telepon penerima tidak tersedia')),
      );
      return;
    }
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    await launchUrl(uri);
  }

  // Buka ruang video call berbasis Jitsi menggunakan roomId
  Future<void> _startVideoCall() async {
    final url = Uri.parse(
      'https://meet.jit.si/integrated_strokes_${widget.roomId}',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = LinearGradient(
      colors: [Colors.teal.shade50, Colors.white],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Konsultasi')),
        body: const Center(
          child: Text('Anda perlu masuk sebelum mengakses konsultasi.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      extendBody: true,
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                widget.recipientName.trim().isNotEmpty
                    ? widget.recipientName.trim().substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Konsultasi aktif • Waktu nyata',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Telepon',
            onPressed: _startPhoneCall,
            icon: const Icon(Icons.call, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Video call',
            onPressed: _startVideoCall,
            icon: const Icon(Icons.videocam_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: gradient)),
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 18,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: StreamBuilder<List<ChatMessage>>(
                      stream: _messagesStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final messages = snapshot.data ?? [];
                        if (messages.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome_outlined,
                                  size: 56,
                                  color: Colors.teal.shade200,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Mulai percakapan Anda',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sampaikan keluhan atau pertanyaan terkait terapi.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          );
                        }

                        _scrollToBottom();

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final showDateChip =
                                index == 0 ||
                                !_isSameDay(
                                  messages[index - 1].createdAt,
                                  message.createdAt,
                                );
                            final isSender = message.senderId == _currentUserId;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showDateChip)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.shade50,
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          border: Border.all(
                                            color: Colors.teal.shade100,
                                          ),
                                        ),
                                        child: Text(
                                          DateFormat(
                                            'EEEE, d MMM',
                                            'id_ID',
                                          ).format(message.createdAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.teal.shade800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                _MessageBubble(
                                  message: message,
                                  isSender: isSender,
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              _MessageComposer(
                controller: _textController,
                isSending: _isSending,
                onSend: _sendMessage,
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.theme,
  });

  final TextEditingController controller;
  final ValueNotifier<bool> isSending;
  final VoidCallback onSend;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorStateOfType<_ConsultationScreenState>();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _ComposerIconButton(
                icon: Icons.photo_outlined,
                tooltip: 'Lampirkan foto',
                onTap: parent?._pickAndSendPhoto,
              ),
              const SizedBox(width: 4),
              _ComposerIconButton(
                icon: Icons.attach_file_rounded,
                tooltip: 'Lampirkan dokumen',
                onTap: parent?._pickAndSendFile,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Tulis pesan...',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ValueListenableBuilder<bool>(
                valueListenable: isSending,
                builder: (context, sending, _) {
                  if (sending) {
                    return const SizedBox(
                      width: 42,
                      height: 42,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.teal.shade500,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: onSend,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isSender});

  final ChatMessage message;
  final bool isSender;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isSender ? Colors.teal.shade50 : Colors.white;
    final alignment = isSender ? Alignment.centerRight : Alignment.centerLeft;
    final textColor = isSender ? Colors.teal.shade900 : Colors.grey.shade900;
    final meta = message.metadata;
    final content = message.content;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: isSender
              ? LinearGradient(
                  colors: [Colors.teal.shade400, Colors.teal.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSender ? null : bubbleColor,
          border: isSender ? null : Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isSender
                ? const Radius.circular(16)
                : const Radius.circular(6),
            bottomRight: isSender
                ? const Radius.circular(6)
                : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isSender
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (meta != null &&
                meta['type'] == 'image' &&
                (meta['url']?.toString().isNotEmpty ?? false))
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    meta['url'] as String,
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width * 0.7,
                  ),
                ),
              ),
            if (meta != null &&
                meta['type'] == 'file' &&
                (meta['url']?.toString().isNotEmpty ?? false))
              InkWell(
                onTap: () async {
                  final url = Uri.parse(meta['url'] as String);
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.insert_drive_file, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        (meta['name']?.toString().isNotEmpty ?? false)
                            ? meta['name'] as String
                            : 'Lampiran',
                        style: TextStyle(color: textColor, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            // Fallback render: jika content adalah URL gambar, tampilkan gambar.
            if (content.trim().isNotEmpty &&
                Uri.tryParse(content)?.hasAbsolutePath == true &&
                _isImageUrl(content))
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  content,
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width * 0.7,
                ),
              )
            else if (content.trim().isNotEmpty)
              Text(
                content,
                style: TextStyle(
                  color: isSender ? Colors.white : textColor,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isSender
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Text(
                  DateFormat.Hm().format(message.createdAt.toLocal()),
                  style: TextStyle(
                    color: isSender
                        ? Colors.white.withOpacity(0.85)
                        : Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                if (isSender) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.teal.shade600),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.teal.shade800,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({
    required this.icon,
    this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.shade100),
          ),
          child: Icon(icon, color: Colors.teal.shade700, size: 20),
        ),
      ),
    );
  }
}
