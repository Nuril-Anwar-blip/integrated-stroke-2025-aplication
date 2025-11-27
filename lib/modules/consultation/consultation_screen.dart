import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'].toString(),
      content: map['content'] ?? '',
      senderId: map['sender_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  final String id;
  final String content;
  final String senderId;
  final DateTime createdAt;
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
      appBar: AppBar(
        elevation: 0.4,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: Text(
                widget.recipientName.trim().isNotEmpty
                    ? widget.recipientName.trim().substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.teal),
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
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Konsultasi aktif',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Telepon',
            onPressed: () {},
            icon: const Icon(Icons.call),
          ),
          IconButton(
            tooltip: 'Video call',
            onPressed: () {},
            icon: const Icon(Icons.videocam_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.verified_user, color: Colors.teal.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Percakapan ini tercatat dan dapat dipantau oleh tim klinis kami.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Mulai percakapan Anda',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sampaikan keluhan atau pertanyaan terkait terapi.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  DateFormat(
                                    'EEEE, d MMM',
                                    'id_ID',
                                  ).format(message.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        _MessageBubble(message: message, isSender: isSender),
                      ],
                    );
                  },
                );
              },
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Lampirkan foto',
              onPressed: () {},
              icon: Icon(Icons.photo_outlined, color: Colors.teal.shade600),
            ),
            IconButton(
              tooltip: 'Lampirkan dokumen',
              onPressed: () {},
              icon: Icon(
                Icons.attach_file_rounded,
                color: Colors.teal.shade600,
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Ketik pesan Anda...',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
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
                  backgroundColor: theme.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: onSend,
                  ),
                );
              },
            ),
          ],
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
    final bubbleColor = isSender ? Colors.teal.shade100 : Colors.white;
    final alignment = isSender ? Alignment.centerRight : Alignment.centerLeft;
    final textColor = isSender ? Colors.teal.shade900 : Colors.grey.shade900;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isSender
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isSender
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isSender
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                if (isSender) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 16, color: Colors.teal),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
