import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';
import '../../../models/social_post_model.dart';
import '../../../providers/social_provider.dart';
import '../../../utils/profanity_filter.dart';
import 'report_dialog.dart';
import 'social_rich_text.dart';

/// Bottom sheet showing a post's threaded comments and a composer.
class CommentThreadSheet extends StatefulWidget {
  final int postId;
  const CommentThreadSheet({super.key, required this.postId});

  @override
  State<CommentThreadSheet> createState() => _CommentThreadSheetState();
}

class _CommentThreadSheetState extends State<CommentThreadSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;
  PostComment? _replyingTo;

  @override
  void initState() {
    super.initState();
    // Load the freshest thread when the sheet opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().loadComments(widget.postId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _initials(String name) => name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0])
      .take(2)
      .join()
      .toUpperCase();

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      Fluttertoast.showToast(msg: 'Cannot send empty text');
      return;
    }
    if (ProfanityFilter.containsProfanity(text)) {
      Fluttertoast.showToast(msg: 'Please remove inappropriate language');
      return;
    }
    setState(() => _submitting = true);
    final ok = await context.read<SocialProvider>().addComment(
          widget.postId,
          text,
          parentCommentId: _replyingTo?.id,
        );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _replyingTo = null;
    });
    if (ok) {
      _controller.clear();
      Fluttertoast.showToast(msg: 'Comment submitted');
    } else {
      Fluttertoast.showToast(msg: 'Error: check your internet and retry');
    }
  }

  Future<void> _report(PostComment c) async {
    final reason = await showReportDialog(context);
    if (reason == null) return;
    final ok = await context.read<SocialProvider>().reportComment(c.id ?? -1, reason);
    Fluttertoast.showToast(
        msg: ok ? 'Reported. Thank you.' : 'Could not submit report');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SocialProvider>();
    final all = provider.commentsFor(widget.postId);
    final topLevel = all.where((c) => c.parentCommentId == null).toList();
    final repliesByParent = <int, List<PostComment>>{};
    for (final c in all) {
      if (c.parentCommentId != null) {
        repliesByParent.putIfAbsent(c.parentCommentId!, () => []).add(c);
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Comments',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(height: 1),
          Expanded(
            child: topLevel.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 90,
                          width: 90,
                          child: Image.asset('assets/icons/no_comment.png'),
                        ),
                        const Text('No comments yet. Leave one',
                            style: TextStyle(color: kScreenDark, fontSize: 15)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: topLevel.length,
                    itemBuilder: (context, i) {
                      final c = topLevel[i];
                      final replies = repliesByParent[c.id] ?? const [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CommentTile(
                            comment: c,
                            initials: _initials(c.userName),
                            onReply: () => setState(() => _replyingTo = c),
                            onReport: () => _report(c),
                          ),
                          ...replies.map((r) => Padding(
                                padding: const EdgeInsets.only(left: 44),
                                child: _CommentTile(
                                  comment: r,
                                  initials: _initials(r.userName),
                                  onReply: () => setState(() => _replyingTo = c),
                                  onReport: () => _report(r),
                                ),
                              )),
                        ],
                      );
                    },
                  ),
          ),
          if (_replyingTo != null)
            Container(
              width: double.infinity,
              color: kGradientLighterBlue,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Replying to ${_replyingTo!.userName}',
                        style: const TextStyle(fontSize: 12)),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _replyingTo = null),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: _replyingTo == null
                          ? 'Add a comment...'
                          : 'Write a reply...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                _submitting
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            height: 24, width: 24, child: CircularProgressIndicator()),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: kCIOPink, size: 32),
                        onPressed: _submit,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final PostComment comment;
  final String initials;
  final VoidCallback onReply;
  final VoidCallback onReport;

  const _CommentTile({
    required this.comment,
    required this.initials,
    required this.onReply,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: kGoldColor,
            child: Text(initials,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  decoration: BoxDecoration(
                    color: kRightBubble.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 2),
                      SocialRichText(
                        text: comment.comment,
                        baseStyle:
                            const TextStyle(fontSize: 13, color: kToggleDark),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: onReply,
                      child: const Text('Reply', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: onReport,
                      child: const Text('Report',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
