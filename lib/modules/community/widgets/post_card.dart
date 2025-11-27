import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/post_model.dart';
import '../video_player_screen.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onCommentTap;
  final VoidCallback? onTap;
  final bool showActions;

  const PostCard({
    Key? key,
    required this.post,
    this.onLikeToggle,
    this.onDelete,
    this.onCommentTap,
    this.onTap,
    this.showActions = true,
  }) : super(key: key);

  String _timeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inMinutes < 60) return '${difference.inMinutes} mnt lalu';
    if (difference.inHours < 24) return '${difference.inHours} jam lalu';
    return DateFormat('d MMM yyyy', 'id_ID').format(time);
  }

  Future<void> _launchUrl(BuildContext context, Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tidak bisa membuka file: $url')));
    }
  }

  void _onShareButtonPressed(BuildContext context) {
    final String shareText =
        "Lihat postingan dari ${post.userName} di aplikasi Integrated Stroke:\n\n"
        "'${post.content}'\n\n"
        "Download aplikasi kami di: [Link Aplikasi Anda]";

    Share.share(shareText);
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Postingan'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus postingan ini? Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            child: const Text('Tidak'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Ya, Hapus', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (onDelete != null) {
                onDelete!();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context, String? type, String url) {
    Widget mediaWidget;
    VoidCallback? onTap;

    switch (type) {
      case 'image':
        mediaWidget = Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
            );
          },
        );
        break;
      case 'video':
        mediaWidget = Container(
          color: Colors.black,
          height: 200,
          child: const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
          ),
        );
        onTap = () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoUrl: url)),
          );
        };
        break;
      case 'file':
      default:
        mediaWidget = InkWell(
          onTap: () => _launchUrl(context, Uri.parse(url)),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file, color: Colors.grey[700]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Lihat Lampiran',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        );
        return mediaWidget;
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: mediaWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final bool isOwner = currentUser != null && currentUser.id == post.userId;
    final likeColor = post.userHasLiked
        ? Theme.of(context).primaryColor
        : Colors.grey[700];
    final likeIcon = post.userHasLiked
        ? Icons.thumb_up_alt_rounded
        : Icons.thumb_up_outlined;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: post.userAvatarUrl.isNotEmpty
                        ? NetworkImage(post.userAvatarUrl)
                        : null,
                    child: post.userAvatarUrl.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _timeAgo(post.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOwner)
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onPressed: () => _showDeleteConfirmationDialog(context),
                        tooltip: 'Opsi',
                      ),
                    ),
                ],
              ),
              if (post.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    post.content,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
              if (post.media_url != null && post.media_url!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: _buildMediaPreview(
                    context,
                    post.media_type,
                    post.media_url!,
                  ),
                ),
              const SizedBox(height: 8),
              if (post.likeCount > 0 || post.commentCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                  child: Row(
                    children: [
                      if (post.likeCount > 0) ...[
                        Icon(
                          Icons.thumb_up_alt_rounded,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text('${post.likeCount} Suka'),
                      ],
                      if (post.likeCount > 0 && post.commentCount > 0)
                        const SizedBox(width: 16),
                      if (post.commentCount > 0) ...[
                        Icon(
                          Icons.comment_rounded,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text('${post.commentCount} Komentar'),
                      ],
                    ],
                  ),
                ),
              if (showActions) ...[
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    PostActionButton(
                      icon: likeIcon,
                      label: 'Suka',
                      onTap: onLikeToggle ?? () {},
                      color: likeColor,
                    ),
                    PostActionButton(
                      icon: Icons.comment_outlined,
                      label: 'Komentar',
                      onTap: onCommentTap ?? () {},
                      color: Colors.grey[700],
                    ),
                    PostActionButton(
                      icon: Icons.share_outlined,
                      label: 'Bagikan',
                      onTap: () => _onShareButtonPressed(context),
                      color: Colors.grey[700],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PostActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const PostActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
