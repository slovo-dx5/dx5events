import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../constants.dart';
import '../../dioServices/dioFetchService.dart';
import '../../models/social_post_model.dart';
import '../../widgets/socialPostWidget.dart';

/// Shows all published posts carrying a given hashtag.
class HashtagFeedScreen extends StatefulWidget {
  final String tag; // without the leading '#'
  const HashtagFeedScreen({super.key, required this.tag});

  @override
  State<HashtagFeedScreen> createState() => _HashtagFeedScreenState();
}

class _HashtagFeedScreenState extends State<HashtagFeedScreen> {
  final List<PostData> _posts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await DioFetchService().fetchPostsByHashtag(tag: widget.tag);
      final list = (res.data['data'] as List)
          .map((e) => PostData.fromJson(e))
          .toList();
      setState(() {
        _posts
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load posts';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('#${widget.tag}')),
      body: _loading
          ? const Center(child: SpinKitFadingCircle(size: 45, color: kPrimaryColor))
          : _error != null
              ? Center(child: Text(_error!))
              : _posts.isEmpty
                  ? const Center(child: Text('No posts with this tag yet'))
                  : ListView.builder(
                      itemCount: _posts.length,
                      itemBuilder: (context, i) =>
                          SocialMediaPost(post: _posts[i]),
                    ),
    );
  }
}
