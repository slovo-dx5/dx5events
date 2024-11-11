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
  final List<Like>? likes;
  final List<CommentModel>? comments;
  final String userName;

  PostData({
    required this.id,
    required this.dateCreated,
    required this.userId,
    required this.pictureLink,
    required this.postDescription,
    this.likes,
    this.comments,
    required this.userName,
  });

  factory PostData.fromJson(Map<String, dynamic> json) {
    return PostData(
      id: json['id'],
      dateCreated: json['date_created'],
      userId: json['user_id'],
      pictureLink: json['picture_link'],
      postDescription: json['post_description'],
      likes: json['likes'] != null
          ? List<Like>.from(json['likes'].map((like) => Like.fromJson(like)))
          : null,
      comments: json['Comments'] != null
          ? List<CommentModel>.from(json['Comments'].map((comment) => CommentModel.fromJson(comment)))
          : null,
      userName: json['user_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date_created': dateCreated,
      'user_id': userId,
      'picture_link': pictureLink,
      'post_description': postDescription,
      'likes': likes != null ? List<dynamic>.from(likes!.map((like) => like.toJson())) : null,
      'Comments': comments != null ? List<dynamic>.from(comments!.map((comment) => comment.toJson())) : null,
      'user_name': userName,
    };
  }
}

class Like {
  final int likerId;
  final int postId;

  Like({
    required this.likerId,
    required this.postId,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
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