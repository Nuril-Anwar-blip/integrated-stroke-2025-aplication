import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MediaType { image, video, file }

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textController = TextEditingController();
  final _maxCharacters = 600;

  bool _isLoading = false;
  File? _selectedFile;
  MediaType? _mediaType;
  String? _fileName;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(MediaType type) async {
    FileType fileType;
    List<String>? allowedExtensions;

    switch (type) {
      case MediaType.image:
        fileType = FileType.image;
        break;
      case MediaType.video:
        fileType = FileType.video;
        break;
      case MediaType.file:
        fileType = FileType.custom;
        allowedExtensions = ['pdf', 'doc', 'docx', 'txt'];
        break;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
      );

      if (result == null) return;

      setState(() {
        _selectedFile = File(result.files.single.path!);
        _mediaType = type;
        _fileName = result.files.single.name;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih file: $e')));
    }
  }

  Future<void> _submitPost() async {
    final content = _textController.text.trim();
    if (content.isEmpty && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tulis sesuatu atau lampirkan media.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? mediaUrl;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw 'Pengguna belum masuk.';

      if (_selectedFile != null && _mediaType != null) {
        final bucket = switch (_mediaType!) {
          MediaType.image => 'post_images',
          MediaType.video => 'post_videos',
          MediaType.file => 'post_files',
        };

        final fileName =
            '${user.id}/${DateTime.now().millisecondsSinceEpoch}_${_fileName ?? 'attachment'}';
        final storage = Supabase.instance.client.storage.from(bucket);
        await storage.upload(fileName, _selectedFile!);
        mediaUrl = storage.getPublicUrl(fileName);
      }

      await Supabase.instance.client.from('posts').insert({
        'user_id': user.id,
        'content': content,
        'media_url': mediaUrl,
        'media_type': _mediaType?.name,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Postingan terkirim!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim postingan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearAttachment() {
    setState(() {
      _selectedFile = null;
      _mediaType = null;
      _fileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bagikan Cerita'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitPost,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Kirim',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _ComposerHeader(maxCharacters: _maxCharacters),
                const SizedBox(height: 12),
                _buildInputCard(),
                const SizedBox(height: 12),
                _buildAttachmentPreview(),
                const SizedBox(height: 12),
                _AttachmentChips(onSelect: (type) => _pickFile(type)),
              ],
            ),
          ),
          _AttachmentToolbar(
            onImageTap: () => _pickFile(MediaType.image),
            onVideoTap: () => _pickFile(MediaType.video),
            onFileTap: () => _pickFile(MediaType.file),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    final remaining = _maxCharacters - _textController.text.length;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textController,
              maxLength: _maxCharacters,
              maxLines: null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText:
                    'Cerita, pertanyaan, atau motivasi untuk komunitas...',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$remaining karakter tersisa',
                style: TextStyle(
                  fontSize: 12,
                  color: remaining < 40 ? Colors.red : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    if (_selectedFile == null || _mediaType == null) {
      return const SizedBox.shrink();
    }

    Widget preview;
    switch (_mediaType!) {
      case MediaType.image:
        preview = ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            _selectedFile!,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        );
        break;
      case MediaType.video:
        preview = _AttachmentPreviewContainer(
          color: Colors.black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_outlined,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _fileName ?? 'Video terpilih',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
        break;
      case MediaType.file:
        preview = _AttachmentPreviewContainer(
          color: Colors.grey[200],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file, size: 48, color: Colors.grey[800]),
              const SizedBox(height: 8),
              Text(
                _fileName ?? 'Lampiran terpilih',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
        break;
    }

    return Stack(
      children: [
        preview,
        Positioned(
          top: 12,
          right: 12,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: _clearAttachment,
            ),
          ),
        ),
      ],
    );
  }
}

class _ComposerHeader extends StatelessWidget {
  const _ComposerHeader({required this.maxCharacters});
  final int maxCharacters;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade600,
              child: const Icon(Icons.forum_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tulis postingan hangat',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Maksimal $maxCharacters karakter, lampirkan foto/video untuk lebih bercerita.',
                    style: TextStyle(color: Colors.blueGrey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentPreviewContainer extends StatelessWidget {
  const _AttachmentPreviewContainer({required this.child, required this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _AttachmentToolbar extends StatelessWidget {
  const _AttachmentToolbar({
    required this.onImageTap,
    required this.onVideoTap,
    required this.onFileTap,
  });

  final VoidCallback onImageTap;
  final VoidCallback onVideoTap;
  final VoidCallback onFileTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _AttachmentButton(
              label: 'Foto',
              icon: Icons.photo_library_outlined,
              color: Colors.green,
              onTap: onImageTap,
            ),
            _AttachmentButton(
              label: 'Video',
              icon: Icons.videocam_outlined,
              color: Colors.redAccent,
              onTap: onVideoTap,
            ),
            _AttachmentButton(
              label: 'Dokumen',
              icon: Icons.attach_file,
              color: Colors.blue,
              onTap: onFileTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentButton extends StatelessWidget {
  const _AttachmentButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color)),
        style: TextButton.styleFrom(foregroundColor: color),
      ),
    );
  }
}

class _AttachmentChips extends StatelessWidget {
  const _AttachmentChips({required this.onSelect});

  final ValueChanged<MediaType> onSelect;

  @override
  Widget build(BuildContext context) {
    final chips = [
      {'type': MediaType.image, 'label': '#tips'},
      {'type': MediaType.video, 'label': '#progress'},
      {'type': MediaType.file, 'label': '#pertanyaan'},
    ];

    return Wrap(
      spacing: 8,
      children: chips
          .map(
            (item) => ActionChip(
              label: Text(item['label']! as String),
              onPressed: () => onSelect(item['type']! as MediaType),
            ),
          )
          .toList(),
    );
  }
}
