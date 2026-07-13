import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../dioServices/dioFetchService.dart';
import '../dioServices/dioPostService.dart';
import '../dioServices/dio_delete_service.dart';
import '../helpers/helper_functions.dart';
import '../models/social_post_model.dart';

/// Central state for the revamped social feed.
///
/// Holds the post list, the current user's reaction per post, per-post comment
/// threads and the block list, and performs **optimistic** reaction/comment
/// mutations against the normalized Directus collections. This removes the old
/// read-modify-PATCH-whole-array + `Navigator.pushReplacement(SocialFeed())`
/// refresh pattern.
class SocialProvider with ChangeNotifier {
  final DioFetchService _fetch = DioFetchService();
  final DioPostService _post = DioPostService();
  final DioDeleteService _delete = DioDeleteService();

  static const int pageSize = 20;

  // ---- Current user -------------------------------------------------------
  int? _userId;
  String _userName = '';
  bool _isAdmin = false;
  int? get currentUserId => _userId;
  String get currentUserName => _userName;
  bool get isAdmin => _isAdmin;

  // ---- Feed state ---------------------------------------------------------
  final List<PostData> _posts = [];
  List<PostData> get posts => List.unmodifiable(_posts);

  bool _loading = false;
  bool get isLoading => _loading;
  bool _loadingMore = false;
  bool get isLoadingMore => _loadingMore;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  String? _error;
  String? get error => _error;
  int _offset = 0;

  // ---- Per-post derived state ---------------------------------------------
  /// postId -> the current user's reaction type (null = not reacted).
  final Map<int, String?> _myReactionType = {};
  /// postId -> the Directus row id of the user's reaction (for update/delete).
  final Map<int, int> _myReactionId = {};
  /// postId -> loaded comment thread.
  final Map<int, List<PostComment>> _comments = {};
  /// Users the current user has blocked (their posts are hidden).
  final Set<int> _blocked = {};

  String? myReaction(int postId) => _myReactionType[postId];
  bool hasReacted(int postId) => _myReactionType[postId] != null;
  List<PostComment> commentsFor(int postId) => _comments[postId] ?? const [];

  // ---- Lifecycle ----------------------------------------------------------

  Future<void> init() async {
    _userId = await getIntPref(kUserID);
    final first = await getStringPref(kFirstName);
    final last = await getStringPref(kLastName);
    _userName = '$first $last'.trim();
    _isAdmin = (await getStringPref(kIsAdmin)) == 'true';
    await _loadBlocks();
    await loadFeed(refresh: true);
  }

  Future<void> _loadBlocks() async {
    if (_userId == null) return;
    try {
      final res = await _fetch.fetchUserBlocks(blockerId: _userId!);
      _blocked
        ..clear()
        ..addAll((res.data['data'] as List)
            .map((e) => UserBlock.fromJson(e).blockedId));
    } catch (_) {/* non-fatal */}
  }

  // ---- Feed ---------------------------------------------------------------

  Future<void> loadFeed({bool refresh = false}) async {
    if (refresh) {
      _offset = 0;
      _hasMore = true;
      _error = null;
    }
    _loading = refresh;
    notifyListeners();
    try {
      final res = await _fetch.fetchSocialFeed(limit: pageSize, offset: _offset);
      final fetched = (res.data['data'] as List)
          .map((e) => PostData.fromJson(e))
          .where((p) => !_blocked.contains(p.userId))
          .toList();
      if (refresh) _posts.clear();
      _posts.addAll(fetched);
      _sortFeed();
      _offset += pageSize;
      _hasMore = fetched.length >= pageSize;
      await _loadMyReactions(fetched.map((p) => p.id).toList());
    } catch (e) {
      _error = 'Failed to load posts';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Silent poll used for near-real-time updates: re-fetches the first page and
  /// merges new posts / updated counts without a loading spinner. This is the
  /// polling half of the realtime strategy (a Directus WebSocket subscription
  /// can later replace/augment it when `WEBSOCKETS_ENABLED` is on).
  Future<void> pollNewPosts() async {
    try {
      final res = await _fetch.fetchSocialFeed(limit: pageSize, offset: 0);
      final fetched = (res.data['data'] as List)
          .map((e) => PostData.fromJson(e))
          .where((p) => !_blocked.contains(p.userId))
          .toList();
      final newIds = <int>[];
      for (final p in fetched) {
        final idx = _indexOf(p.id);
        if (idx == -1) {
          _posts.add(p);
          newIds.add(p.id);
        } else {
          // Refresh denormalized counts but keep any optimistic local state.
          _replace(idx, _posts[idx].copyWith(
            reactionCount: p.reactionCount,
            commentCount: p.commentCount,
            status: p.status,
            isPinned: p.isPinned,
          ));
        }
      }
      if (fetched.isNotEmpty) _sortFeed();
      if (newIds.isNotEmpty) await _loadMyReactions(newIds);
      notifyListeners();
    } catch (_) {/* silent */}
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final res = await _fetch.fetchSocialFeed(limit: pageSize, offset: _offset);
      final fetched = (res.data['data'] as List)
          .map((e) => PostData.fromJson(e))
          .where((p) => !_blocked.contains(p.userId))
          .toList();
      _posts.addAll(fetched);
      _sortFeed();
      _offset += pageSize;
      _hasMore = fetched.length >= pageSize;
      await _loadMyReactions(fetched.map((p) => p.id).toList());
    } catch (_) {
      // keep existing list; surface nothing intrusive
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  /// Pinned posts float to the top; otherwise newest-first (feed already sorted
  /// by the API, this only lifts pinned ones).
  void _sortFeed() {
    _posts.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.dateCreated.compareTo(a.dateCreated);
    });
  }

  Future<void> _loadMyReactions(List<int> postIds) async {
    if (_userId == null || postIds.isEmpty) return;
    // Fetch this user's reactions for the given posts in one call.
    try {
      for (final id in postIds) {
        final res = await _fetch.fetchPostReactions(postId: id);
        final rows = (res.data['data'] as List)
            .map((e) => ReactionModel.fromJson(e))
            .toList();
        final mine = rows.where((r) => r.userId == _userId).toList();
        if (mine.isNotEmpty) {
          _myReactionType[id] = mine.first.type;
          if (mine.first.id != null) _myReactionId[id] = mine.first.id!;
        } else {
          _myReactionType.remove(id);
          _myReactionId.remove(id);
        }
      }
    } catch (_) {/* non-fatal */}
  }

  int _indexOf(int postId) => _posts.indexWhere((p) => p.id == postId);

  void _replace(int index, PostData updated) {
    _posts[index] = updated;
  }

  // ---- Reactions (optimistic) --------------------------------------------

  /// Adds, changes, or removes the current user's reaction on [postId].
  Future<void> toggleReaction(int postId, {String type = ReactionType.like}) async {
    if (_userId == null) return;
    final idx = _indexOf(postId);
    if (idx == -1) return;
    final post = _posts[idx];
    final current = _myReactionType[postId];

    if (current == null) {
      // ADD
      _myReactionType[postId] = type;
      _replace(idx, post.copyWith(reactionCount: post.reactionCount + 1));
      notifyListeners();
      try {
        final res = await _post.createReaction(body: {
          'post_id': postId,
          'user_id': _userId,
          'user_name': _userName,
          'type': type,
        });
        final newId = res.data['data']?['id'];
        if (newId is int) _myReactionId[postId] = newId;
        _bumpReactionCount(postId);
        UserPointsService().createOrUpdateUserPoints(userId: _userId!, actionId: 13);
      } catch (_) {
        _myReactionType.remove(postId);
        _replace(idx, _posts[idx].copyWith(reactionCount: (_posts[idx].reactionCount - 1).clamp(0, 1 << 30)));
        notifyListeners();
      }
    } else if (current == type) {
      // REMOVE
      final rid = _myReactionId[postId];
      _myReactionType.remove(postId);
      _replace(idx, post.copyWith(reactionCount: (post.reactionCount - 1).clamp(0, 1 << 30)));
      notifyListeners();
      try {
        if (rid != null) await _delete.deleteReaction(reactionId: rid);
        _myReactionId.remove(postId);
        _bumpReactionCount(postId);
      } catch (_) {
        _myReactionType[postId] = current;
        _replace(idx, _posts[idx].copyWith(reactionCount: _posts[idx].reactionCount + 1));
        notifyListeners();
      }
    } else {
      // CHANGE TYPE
      final rid = _myReactionId[postId];
      _myReactionType[postId] = type;
      notifyListeners();
      try {
        if (rid != null) {
          await _post.updateReaction(reactionId: rid, body: {'type': type});
        }
      } catch (_) {
        _myReactionType[postId] = current;
        notifyListeners();
      }
    }
  }

  /// Persist the denormalized counter so other clients see the new total.
  Future<void> _bumpReactionCount(int postId) async {
    final idx = _indexOf(postId);
    if (idx == -1) return;
    try {
      await _post.patchSocialPost(
          body: {'reaction_count': _posts[idx].reactionCount}, postID: postId);
    } catch (_) {/* best-effort */}
  }

  // ---- Comments (optimistic) ---------------------------------------------

  Future<void> loadComments(int postId) async {
    try {
      final res = await _fetch.fetchPostComments(postId: postId);
      _comments[postId] = (res.data['data'] as List)
          .map((e) => PostComment.fromJson(e))
          .toList();
      notifyListeners();
    } catch (_) {/* non-fatal */}
  }

  Future<bool> addComment(int postId, String text, {int? parentCommentId}) async {
    if (_userId == null || text.trim().isEmpty) return false;
    final idx = _indexOf(postId);
    // Optimistic: add a temporary comment + bump count.
    final optimistic = PostComment(
      postId: postId,
      parentCommentId: parentCommentId,
      userId: _userId!,
      userName: _userName,
      comment: text.trim(),
      dateCreated: DateTime.now().toUtc().toIso8601String(),
    );
    _comments.putIfAbsent(postId, () => []);
    _comments[postId]!.add(optimistic);
    if (idx != -1) {
      _replace(idx, _posts[idx].copyWith(commentCount: _posts[idx].commentCount + 1));
    }
    notifyListeners();

    try {
      await _post.createComment(body: optimistic.toJson());
      if (idx != -1) {
        await _post.patchSocialPost(
            body: {'comment_count': _posts[idx].commentCount}, postID: postId);
      }
      UserPointsService().createOrUpdateUserPoints(userId: _userId!, actionId: 12);
      // Re-sync the thread so the temp row gets its real id.
      await loadComments(postId);
      return true;
    } catch (_) {
      _comments[postId]?.remove(optimistic);
      if (idx != -1) {
        _replace(idx, _posts[idx].copyWith(
            commentCount: (_posts[idx].commentCount - 1).clamp(0, 1 << 30)));
      }
      notifyListeners();
      return false;
    }
  }

  // ---- Moderation ---------------------------------------------------------

  Future<bool> reportPost(int postId, String reason) =>
      _report(PostReport.targetPost, postId, reason);

  Future<bool> reportComment(int commentId, String reason) =>
      _report(PostReport.targetComment, commentId, reason);

  Future<bool> _report(String targetType, int targetId, String reason) async {
    if (_userId == null) return false;
    try {
      await _post.createReport(body: PostReport(
        targetType: targetType,
        targetId: targetId,
        reporterId: _userId!,
        reason: reason,
      ).toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> blockUser(int blockedId) async {
    if (_userId == null || blockedId == _userId) return false;
    try {
      await _post.createBlock(
          body: UserBlock(blockerId: _userId!, blockedId: blockedId).toJson());
      _blocked.add(blockedId);
      _posts.removeWhere((p) => p.userId == blockedId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Admin-only: hide or remove a post via its status.
  Future<bool> setPostStatus(int postId, String status) async {
    if (!_isAdmin) return false;
    try {
      await _post.patchSocialPost(body: {'status': status}, postID: postId);
      if (status != 'published') {
        _posts.removeWhere((p) => p.id == postId);
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
