import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../providers/social_provider.dart';
import '../../widgets/profile_initials_widget.dart';
import '../../widgets/socialPostWidget.dart';
import 'createPostScreen.dart';

class SocialFeed extends StatefulWidget {
  const SocialFeed({super.key});

  @override
  State<SocialFeed> createState() => _SocialFeedState();
}

class _SocialFeedState extends State<SocialFeed> {
  final ScrollController _scroll = ScrollController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Initialize the provider (user, blocks, first page) once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().init();
    });
    _scroll.addListener(_onScroll);
    // Near-real-time: silently poll for new posts / updated counts.
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted) context.read<SocialProvider>().pollNewPosts();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      context.read<SocialProvider>().loadMore();
    }
  }

  Future<void> _openCreatePost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SocialProvider>();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          color: kCIOPink,
        ),
        title: const Text("Social Feed"),
      ),
      body: Column(
        children: [
          // Composer bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                ProfileInitials(circleRadius: 22, fontSize: 20),
                horizontalSpace(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: _openCreatePost,
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Say something',
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 20.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(SocialProvider provider) {
    if (provider.isLoading && provider.posts.isEmpty) {
      return const Center(child: SpinKitFadingCircle(size: 50, color: kPrimaryColor));
    }
    if (provider.error != null && provider.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.error!),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => provider.loadFeed(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (provider.posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.loadFeed(refresh: true),
        child: ListView(
          children: const [
            SizedBox(height: 200),
            Center(child: Text('No posts yet. Be the first to say something!')),
          ],
        ),
      );
    }

    final posts = provider.posts;
    return RefreshIndicator(
      onRefresh: () => provider.loadFeed(refresh: true),
      child: ListView.builder(
        controller: _scroll,
        itemCount: posts.length + (provider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return SocialMediaPost(post: posts[index]);
        },
      ),
    );
  }
}
