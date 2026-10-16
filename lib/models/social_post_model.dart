// Social feature models.
//
// The revamped feature normalizes likes/comments into their own Directus
// collections (see docs/features/social-revamp-directus-schema.md):
//   - PostData        -> `Social`
//   - ReactionModel   -> `post_reactions`
//   - PostComment     -> `post_comments`  (threaded via parentCommentId)
//   - SocialProfileModel -> `social_profiles`
//   - PostReport      -> `post_reports`
//   - UserBlock       -> `user_blocks`
//
// The legacy embedded `likes`/`Comments` fields on PostData (and the old
// LikesModel / CommentModel) are kept for backward compatibility during the
// migration and will be removed once the whole UI is on the new collections.

class PostModel {
  final List<PostData> data;

  PostModel({required this.data});

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      data: List<PostData>.from(json['data'].map((post) => PostData.fromJson(post))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': List<dynamic>.from(data.map((post) => post.toJson())),
    };
  }
}

class PostData {
  final int id;
  final String dateCreated;
  final int userId;
  final String pictureLink;
  final String postDescription;
  final String userName;

  // New normalized/moderation fields (nullable so pre-migration rows still parse).
  final String status; // published | hidden | removed
  final bool isPinned;
  final int reactionCount;
  final int commentCount;
  final List<String> hashtags;

  // Legacy embedded arrays — deprecated, kept for back-compat only.
  @Deprecated('Use post_reactions collection via ReactionModel')
  final List<LikesModel>? likes;
  @Deprecated('Use post_comments collection via PostComment')
  final List<CommentModel>? comments;

  PostData({
    required this.id,
    required this.dateCreated,
    required this.userId,
    required this.pictureLink,
    required this.postDescription,
    required this.userName,
    this.status = 'published',
    this.isPinned = false,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.hashtags = const [],
    this.likes,
    this.comments,
  });

  static List<String> _parseHashtags(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String && raw.isNotEmpty) {
      return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  factory PostData.fromJson(Map<String, dynamic> json) {
    return PostData(
      id: json['id'],
      dateCreated: json['date_created'],
      userId: json['user_id'],
      pictureLink: json['picture_link'],
      postDescription: json['post_description'],
      userName: json['user_name'],
      status: json['status'] ?? 'published',
      isPinned: json['is_pinned'] == true || json['is_pinned'] == 1,
      reactionCount: json['reaction_count'] ?? (json['likes'] is List ? (json['likes'] as List).length : 0),
      commentCount: json['comment_count'] ?? (json['Comments'] is List ? (json['Comments'] as List).length : 0),
      hashtags: _parseHashtags(json['hashtags']),
      likes: json['likes'] != null
          ? List<LikesModel>.from(json['likes'].map((like) => LikesModel.fromJson(like)))
          : null,
      comments: json['Comments'] != null
          ? List<CommentModel>.from(json['Comments'].map((comment) => CommentModel.fromJson(comment)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date_created': dateCreated,
      'user_id': userId,
      'picture_link': pictureLink,
      'post_description': postDescription,
      'user_name': userName,
      'status': status,
      'is_pinned': isPinned,
      'reaction_count': reactionCount,
      'comment_count': commentCount,
      'hashtags': hashtags,
    };
  }

  PostData copyWith({
    String? status,
    bool? isPinned,
    int? reactionCount,
    int? commentCount,
    List<String>? hashtags,
  }) {
    return PostData(
      id: id,
      dateCreated: dateCreated,
      userId: userId,
      pictureLink: pictureLink,
      postDescription: postDescription,
      userName: userName,
      status: status ?? this.status,
      isPinned: isPinned ?? this.isPinned,
      reactionCount: reactionCount ?? this.reactionCount,
      commentCount: commentCount ?? this.commentCount,
      hashtags: hashtags ?? this.hashtags,
      likes: likes,
      comments: comments,
    );
  }
}

/// Reaction types stored in `post_reactions.type`.
class ReactionType {
  static const String like = 'like';
  static const String love = 'love';
  static const String laugh = 'laugh';
  static const String celebrate = 'celebrate';
  static const String insightful = 'insightful';

  static const List<String> all = [like, love, laugh, celebrate, insightful];

  static const Map<String, String> emoji = {
    like: '👍',
    love: '❤️',
    laugh: '😂',
    celebrate: '🎉',
    insightful: '💡',
  };

  static const Map<String, String> label = {
    like: 'Like',
    love: 'Love',
    laugh: 'Haha',
    celebrate: 'Celebrate',
    insightful: 'Insightful',
  };

  static String emojiFor(String type) => emoji[type] ?? emoji[like]!;
  static String labelFor(String type) => label[type] ?? label[like]!;
  static bool isValid(String type) => all.contains(type);
}

/// A row in `post_reactions`. One per (post, user).
class ReactionModel {
  final int? id;
  final int postId;
  final int userId;
  final String userName;
  final String type;
  final String? dateCreated;

  ReactionModel({
    this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.type = ReactionType.like,
    this.dateCreated,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    // post_id may come back as an int id or an expanded object.
    final rawPost = json['post_id'];
    return ReactionModel(
      id: json['id'],
      postId: rawPost is Map ? rawPost['id'] : rawPost,
      userId: json['user_id'],
      userName: json['user_name'] ?? '',
      type: json['type'] ?? ReactionType.like,
      dateCreated: json['date_created'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'user_id': userId,
      'user_name': userName,
      'type': type,
    };
  }
}

/// A row in `post_comments`. Top-level when [parentCommentId] is null,
/// otherwise a reply to that comment (threading).
class PostComment {
  final int? id;
  final int postId;
  final int? parentCommentId;
  final int userId;
  final String userName;
  final String comment;
  final String status; // published | hidden | removed
  final String? dateCreated;

  PostComment({
    this.id,
    required this.postId,
    this.parentCommentId,
    required this.userId,
    required this.userName,
    required this.comment,
    this.status = 'published',
    this.dateCreated,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    final rawPost = json['post_id'];
    final rawParent = json['parent_comment_id'];
    return PostComment(
      id: json['id'],
      postId: rawPost is Map ? rawPost['id'] : rawPost,
      parentCommentId: rawParent is Map ? rawParent['id'] : rawParent,
      userId: json['user_id'],
      userName: json['user_name'] ?? '',
      comment: json['comment'] ?? '',
      status: json['status'] ?? 'published',
      dateCreated: json['date_created'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      if (parentCommentId != null) 'parent_comment_id': parentCommentId,
      'user_id': userId,
      'user_name': userName,
      'comment': comment,
      'status': status,
    };
  }
}

/// A row in `social_profiles`. Avatar falls back to colored initials when null.
class SocialProfileModel {
  final int? id;
  final int userId;
  final String? avatar; // directus file uuid
  final String? headline;
  final String? bio;

  SocialProfileModel({
    this.id,
    required this.userId,
    this.avatar,
    this.headline,
    this.bio,
  });

  factory SocialProfileModel.fromJson(Map<String, dynamic> json) {
    return SocialProfileModel(
      id: json['id'],
      userId: json['user_id'],
      avatar: json['avatar'],
      headline: json['headline'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'avatar': avatar,
      'headline': headline,
      'bio': bio,
    };
  }
}

/// A row in `post_reports`.
class PostReport {
  static const String targetPost = 'post';
  static const String targetComment = 'comment';

  final int? id;
  final String targetType; // post | comment
  final int targetId;
  final int reporterId;
  final String reason;

  PostReport({
    this.id,
    required this.targetType,
    required this.targetId,
    required this.reporterId,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'target_type': targetType,
      'target_id': targetId,
      'reporter_id': reporterId,
      'reason': reason,
      'resolved': false,
    };
  }
}

/// A row in `user_blocks`.
class UserBlock {
  final int? id;
  final int blockerId;
  final int blockedId;

  UserBlock({this.id, required this.blockerId, required this.blockedId});

  factory UserBlock.fromJson(Map<String, dynamic> json) {
    return UserBlock(
      id: json['id'],
      blockerId: json['blocker_id'],
      blockedId: json['blocked_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blocker_id': blockerId,
      'blocked_id': blockedId,
    };
  }
}

// ---------------------------------------------------------------------------
// Legacy models (embedded arrays) — retained during migration only.
// ---------------------------------------------------------------------------

class LikesModel {
  final int likerId;
  final int postId;

  LikesModel({
    required this.likerId,
    required this.postId,
  });

  factory LikesModel.fromJson(Map<String, dynamic> json) {
    return LikesModel(
      likerId: json['liker_id'],
      postId: json['post_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'liker_id': likerId,
      'post_id': postId,
    };
  }
}

class CommentModel {
  final String comment;
  final int commenterId;
  final int postId;
  final String commenterName;

  CommentModel({
    required this.comment,
    required this.commenterId,
    required this.postId,
    required this.commenterName,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      comment: json['comment'],
      commenterId: json['commenter_id'],
      postId: json['post_id'],
      commenterName: json['commentor_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment': comment,
      'commenter_id': commenterId,
      'post_id': postId,
      'commentor_name': commenterName,
    };
  }
}
