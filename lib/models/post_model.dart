// Lokasi: models/post_model.dart

class Post {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final DateTime createdAt;
  final String content;
  final String? media_url;
  final String? media_type;
  final int likeCount;
  final int commentCount;
  final bool userHasLiked;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.createdAt,
    required this.content,
    this.media_url,
    this.media_type,
    required this.likeCount,
    required this.commentCount,
    required this.userHasLiked,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      userId: map['user_id'],
      userName: map['user_full_name'] ?? 'Nama Pengguna',
      userAvatarUrl: map['user_avatar_url'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      content: map['content'] ?? '',
      media_url: map['media_url'],
      media_type: map['media_type'],
      commentCount: map['comment_count']?.toInt() ?? 0,
      likeCount: map['like_count']?.toInt() ?? 0,
      userHasLiked: map['user_has_liked'] ?? false,
    );
  }

  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    DateTime? createdAt,
    String? content,
    String? media_url,
    String? media_type,
    int? likeCount,
    int? commentCount,
    bool? userHasLiked,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      createdAt: createdAt ?? this.createdAt,
      content: content ?? this.content,
      media_url: media_url ?? this.media_url,
      media_type: media_type ?? this.media_type,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      userHasLiked: userHasLiked ?? this.userHasLiked,
    );
  }
}
