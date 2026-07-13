import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants.dart';
import '../../dioServices/dioFetchService.dart';
import '../../dioServices/dioPostService.dart';
import '../../helpers/helper_functions.dart';
import '../../models/social_post_model.dart';
import '../../utils/directus_image.dart';
import '../../widgets/socialPostWidget.dart';

/// A user's social profile: avatar/headline/bio + their posts.
/// The owner can edit their avatar, headline and bio.
class SocialProfileScreen extends StatefulWidget {
  final int userId;
  final String userName;
  const SocialProfileScreen({super.key, required this.userId, required this.userName});

  @override
  State<SocialProfileScreen> createState() => _SocialProfileScreenState();
}

class _SocialProfileScreenState extends State<SocialProfileScreen> {
  SocialProfileModel? _profile;
  final List<PostData> _posts = [];
  bool _loading = true;
  bool _saving = false;
  int? _currentUserId;

  bool get _isOwner => _currentUserId == widget.userId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _currentUserId = await getIntPref(kUserID);
    await _load();
  }

  Future<void> _load() async {
    try {
      final profRes = await DioFetchService().fetchSocialProfile(userId: widget.userId);
      final profList = profRes.data['data'] as List;
      final postsRes = await DioFetchService().fetchPostsByUser(userId: widget.userId);
      final posts = (postsRes.data['data'] as List)
          .map((e) => PostData.fromJson(e))
          .toList();
      setState(() {
        _profile = profList.isNotEmpty ? SocialProfileModel.fromJson(profList.first) : null;
        _posts
          ..clear()
          ..addAll(posts);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _initials(String name) => name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0])
      .take(2)
      .join()
      .toUpperCase();

  Future<String?> _uploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 75, maxWidth: 800);
    if (picked == null) return _profile?.avatar;
    try {
      final ext = picked.path.split('.').last;
      final mf = await MultipartFile.fromFile(picked.path,
          filename: 'avatar_${widget.userId}.$ext',
          contentType: MediaType('image', ext));
      final formData = FormData.fromMap({
        'folder': '4b5625d4-8ff7-4af0-bad2-caa451357e17',
        'title': mf,
      });
      final res = await DioPostService().uploadProfilePic(formData);
      final map = json.decode(json.encode(res.data));
      return map['data']['id'] as String?;
    } catch (_) {
      Fluttertoast.showToast(msg: 'Avatar upload failed');
      return _profile?.avatar;
    }
  }

  Future<void> _editProfile() async {
    final headlineC = TextEditingController(text: _profile?.headline ?? '');
    final bioC = TextEditingController(text: _profile?.bio ?? '');
    String? newAvatar = _profile?.avatar;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16, right: 16, top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Edit profile',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final id = await _uploadAvatar();
                    setModal(() => newAvatar = id);
                  },
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: kGoldColor,
                    backgroundImage: DirectusImage.hasImage(newAvatar)
                        ? NetworkImage(DirectusImage.avatar(newAvatar!))
                        : null,
                    child: DirectusImage.hasImage(newAvatar)
                        ? null
                        : const Icon(Icons.camera_alt, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: headlineC,
                  decoration: const InputDecoration(
                      labelText: 'Headline', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bioC,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Bio', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: kCIOPink),
                    onPressed: _saving
                        ? null
                        : () async {
                            setModal(() => _saving = true);
                            await _saveProfile(
                                newAvatar, headlineC.text.trim(), bioC.text.trim());
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          },
                    child: _saving
                        ? const SizedBox(
                            height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white))
                        : const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
    setState(() => _saving = false);
  }

  Future<void> _saveProfile(String? avatar, String headline, String bio) async {
    final body = {
      'user_id': widget.userId,
      'avatar': avatar,
      'headline': headline,
      'bio': bio,
    };
    try {
      if (_profile?.id != null) {
        await DioPostService().updateSocialProfile(profileId: _profile!.id!, body: body);
      } else {
        await DioPostService().createSocialProfile(body: body);
      }
      await _load();
      Fluttertoast.showToast(msg: 'Profile updated');
    } catch (_) {
      Fluttertoast.showToast(msg: 'Could not save profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        actions: [
          if (_isOwner)
            IconButton(onPressed: _editProfile, icon: const Icon(Icons.edit)),
        ],
      ),
      body: _loading
          ? const Center(child: SpinKitFadingCircle(size: 45, color: kPrimaryColor))
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: kGoldColor,
                        backgroundImage: DirectusImage.hasImage(_profile?.avatar)
                            ? NetworkImage(DirectusImage.avatar(_profile!.avatar!))
                            : null,
                        child: DirectusImage.hasImage(_profile?.avatar)
                            ? null
                            : Text(_initials(widget.userName),
                                style: const TextStyle(color: Colors.white, fontSize: 28)),
                      ),
                      const SizedBox(height: 10),
                      Text(widget.userName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if ((_profile?.headline ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(_profile!.headline!,
                              style: const TextStyle(color: Colors.grey)),
                        ),
                      if ((_profile?.bio ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_profile!.bio!, textAlign: TextAlign.center),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                if (_posts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No posts yet')),
                  )
                else
                  ..._posts.map((p) => SocialMediaPost(post: p)),
              ],
            ),
    );
  }
}
