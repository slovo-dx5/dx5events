import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/social_post_model.dart';
import '../providers/social_provider.dart';
import '../screens/dx5ve_social/social_profile_screen.dart';
import '../screens/dx5ve_social/widgets/comment_thread_sheet.dart';
import '../screens/dx5ve_social/widgets/reaction_picker.dart';
import '../screens/dx5ve_social/widgets/report_dialog.dart';
import '../screens/dx5ve_social/widgets/social_rich_text.dart';
import '../utils/directus_image.dart';

/// A single feed post card. Reads reaction/comment state from [SocialProvider]
/// and performs optimistic mutations through it.
class SocialMediaPost extends StatefulWidget {
  final PostData post;
  const SocialMediaPost({super.key, required this.post});

  @override
  State<SocialMediaPost> createState() => _SocialMediaPostState();
}

class _SocialMediaPostState extends State<SocialMediaPost> {
  bool _isExpanded = false;
  late final Color _avatarColor =
      predefinedColors[Random().nextInt(predefinedColors.length)];

  PostData get post => widget.post;

  String _formatDate(String dateStr) {
    try {
      return intl.DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return '';
    }
  }

  String _initials(String fullName) => fullName
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0])
      .take(2)
      .join()
      .toUpperCase();

  void _openProfile() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SocialProfileScreen(
        userId: post.userId,
        userName: post.userName,
      ),
    ));
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: CommentThreadSheet(postId: post.id),
      ),
    );
  }

  Future<void> _onMenuSelected(String value, SocialProvider provider) async {
    switch (value) {
      case 'report':
        final reason = await showReportDialog(context);
        if (reason == null) return;
        final ok = await provider.reportPost(post.id, reason);
        Fluttertoast.showToast(
            msg: ok ? 'Reported. Thank you.' : 'Could not submit report');
        break;
      case 'block':
        final ok = await provider.blockUser(post.userId);
        Fluttertoast.showToast(
            msg: ok ? 'User blocked' : 'Could not block user');
        break;
      case 'hide':
        await provider.setPostStatus(post.id, 'hidden');
        Fluttertoast.showToast(msg: 'Post hidden');
        break;
      case 'remove':
        await provider.setPostStatus(post.id, 'removed');
        Fluttertoast.showToast(msg: 'Post removed');
        break;
    }
  }

  void _viewImage() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PostImageViewer(assetId: post.pictureLink),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SocialProvider>();
    final myType = provider.myReaction(post.id);
    final reacted = myType != null;
    final isOwn = provider.currentUserId == post.userId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              GestureDetector(
                onTap: _openProfile,
                child: CircleAvatar(
                  backgroundColor: _avatarColor,
                  radius: 24,
                  child: Text(_initials(post.userName),
                      style: const TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: _openProfile,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(post.userName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (post.isPinned)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Icons.push_pin, size: 14, color: kCIOPink),
                            ),
                        ],
                      ),
                      Text(_formatDate(post.dateCreated),
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz),
                onSelected: (v) => _onMenuSelected(v, provider),
                itemBuilder: (context) => [
                  if (!isOwn)
                    const PopupMenuItem(value: 'report', child: Text('Report post')),
                  if (!isOwn)
                    const PopupMenuItem(value: 'block', child: Text('Block user')),
                  if (provider.isAdmin) ...[
                    const PopupMenuItem(value: 'hide', child: Text('Hide (admin)')),
                    const PopupMenuItem(value: 'remove', child: Text('Remove (admin)')),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description with tappable #/@ + Read More
          if (post.postDescription.trim().isNotEmpty) ...[
            SocialRichText(
              text: post.postDescription,
              maxLines: _isExpanded ? null : 4,
            ),
            _ReadMoreToggle(
              text: post.postDescription,
              expanded: _isExpanded,
              onToggle: () => setState(() => _isExpanded = !_isExpanded),
            ),
            const SizedBox(height: 8),
          ],

          // Optimized image
          if (DirectusImage.hasImage(post.pictureLink))
            GestureDetector(
              onTap: _viewImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: DirectusImage.thumb(post.pictureLink),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (c, _) => Container(
                    height: 200,
                    color: Colors.grey.withOpacity(0.15),
                    child: const Center(
                        child: SizedBox(
                            height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                  errorWidget: (c, _, __) => Container(
                    height: 120,
                    color: Colors.grey.withOpacity(0.15),
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),

          // Reactions + comments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => provider.toggleReaction(
                    post.id, type: myType ?? ReactionType.like),
                onLongPress: () async {
                  final picked = await showReactionPicker(context);
                  if (picked != null) {
                    provider.toggleReaction(post.id, type: picked);
                  }
                },
                child: Row(
                  children: [
                    if (reacted)
                      Text(ReactionType.emojiFor(myType), style: const TextStyle(fontSize: 20))
                    else
                      const Icon(Icons.favorite_border, color: kPrimaryColor, size: 24),
                    const SizedBox(width: 6),
                    Text(
                      reacted ? ReactionType.labelFor(myType) : 'Like',
                      style: TextStyle(
                        color: reacted ? kPrimaryColor : null,
                        fontWeight: reacted ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(post.reactionCount.toString()),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _openComments,
                child: Row(
                  children: [
                    const Icon(Icons.mode_comment_outlined, color: Colors.grey, size: 22),
                    const SizedBox(width: 6),
                    Text(post.commentCount.toString()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shows a "Read More/Less" toggle only when [text] overflows [collapsedLines].
class _ReadMoreToggle extends StatelessWidget {
  final String text;
  final bool expanded;
  final VoidCallback onToggle;
  final int collapsedLines;

  const _ReadMoreToggle({
    required this.text,
    required this.expanded,
    required this.onToggle,
    this.collapsedLines = 4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: text, style: const TextStyle(fontSize: 14)),
          maxLines: collapsedLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        if (!tp.didExceedMaxLines) return const SizedBox.shrink();
        return GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(expanded ? 'Show Less' : 'Read More',
                style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

/// Full-screen, zoomable viewer for a post image (full-resolution transform).
class _PostImageViewer extends StatelessWidget {
  final String assetId;
  const _PostImageViewer({required this.assetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: DirectusImage.full(assetId),
            fit: BoxFit.contain,
            placeholder: (c, _) =>
                const CircularProgressIndicator(color: Colors.white),
            errorWidget: (c, _, __) =>
                const Icon(Icons.broken_image, color: Colors.white54, size: 48),
          ),
        ),
      ),
    );
  }
}
