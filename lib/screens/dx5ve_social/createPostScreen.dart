import 'dart:convert';
import 'dart:io';
import 'package:dx5veevents/dioServices/dioPostService.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../helpers/analytics_helper.dart';
import '../../helpers/helper_functions.dart';
import '../../providers/social_provider.dart';
import '../../utils/profanity_filter.dart';
import '../../utils/social_text_parser.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _postTextController = TextEditingController();
  String? firstName;
  String? lastName;
  XFile? _pickedImage;
  bool hasPickedImage = false;
  int? userID;
  File? crpdFIle;
  bool isCreatingPost = false;
  String? imageID;

  @override
  void initState() {
    getUserDetails();
    super.initState();
  }

  /// Picks an image, downscaled + compressed on-device (image_picker's built-in
  /// [imageQuality]/[maxWidth]) so uploads are small and fast.
  Future<XFile?> pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (pickedImage != null) {
      setState(() => _pickedImage = pickedImage);
    }
    return pickedImage;
  }

  Future<MultipartFile> convertToMultipartFile(File imageFile, ownerName) async {
    final fileExtension = imageFile.path.split('.').last;
    return MultipartFile.fromFile(
      imageFile.path,
      filename: '$ownerName.$fileExtension',
      contentType: MediaType("image", fileExtension),
    );
  }

  Future selectImage() async {
    var pickedImage = await pickImage();
    if (pickedImage == null) return null;
    return File(pickedImage.path);
  }

  Future uploadImage(ownerName, ownerID, File croppedFile) async {
    try {
      final imageFile = await convertToMultipartFile(croppedFile, ownerName);
      final formData = FormData.fromMap({
        'folder': '4b5625d4-8ff7-4af0-bad2-caa451357e17',
        'title': imageFile,
      });
      final response = await DioPostService().uploadProfilePic(formData);
      Map<String, dynamic> jsonResponse = json.decode(json.encode(response.data));
      setState(() => imageID = jsonResponse['data']['id']);
      return imageID;
    } catch (e) {
      if (e is DioError && e.response != null) {
        print("image upload error is ${e.response!.data}");
      }
      print('Error: $e');
      return null;
    }
  }

  getUserDetails() async {
    getStringPref(kFirstName).then((value) => setState(() => firstName = value));
    getIntPref(kUserID).then((value) => setState(() => userID = value));
    getStringPref(kLastName).then((value) {
      setState(() => lastName = value == "" ? "." : value);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (ProfanityFilter.containsProfanity(_postTextController.text)) {
      Fluttertoast.showToast(
          backgroundColor: kKeyRedBG,
          msg: "Please remove inappropriate language before posting");
      return;
    }

    setState(() => isCreatingPost = true);

    if (hasPickedImage && crpdFIle != null) {
      final value = await uploadImage(firstName, userID, crpdFIle!);
      setState(() => imageID = value);
    }

    try {
      final hashtags = SocialTextParser.extractHashtags(_postTextController.text);
      await DioPostService().createSocialPost(body: {
        "user_id": userID,
        "picture_link": imageID ?? "no image",
        "post_description": _postTextController.text,
        "user_name": "$firstName $lastName",
        "status": "published",
        "reaction_count": 0,
        "comment_count": 0,
        "hashtags": hashtags,
      });
      await Dx5veAnalytics().logdx5veEvent(eventName: "socialPostCreated");

      Fluttertoast.showToast(msg: "Post created successfully");
      _postTextController.clear();
      if (!mounted) return;
      // Refresh the live feed instead of the old pushReplacement hack.
      await context.read<SocialProvider>().loadFeed(refresh: true);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      Fluttertoast.showToast(
          backgroundColor: kKeyRedBG,
          msg: "Error: check your internet and try again");
    } finally {
      if (mounted) {
        setState(() {
          isCreatingPost = false;
          crpdFIle = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kLighterGreenAccent,
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close)),
                    const Spacer(),
                    const Text("New Post",
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20)),
                    const Spacer(),
                  ],
                ),
                verticalSpace(height: 10),
                _pickedImage != null
                    ? Image.file(File(_pickedImage!.path), width: 200, height: 200)
                    : const SizedBox(height: 20),
                verticalSpace(height: 10),
                TextFormField(
                  keyboardType: TextInputType.multiline,
                  controller: _postTextController,
                  maxLines: null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter some text';
                    } else if (value.length < 15) {
                      return "Your post must be at least 15 characters";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Your post goes here...  use #tags and @mentions',
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 60.0, horizontal: 10.0),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(fontSize: 16.0, color: kDarkCard),
                ),
                verticalSpace(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final value = await selectImage();
                        if (value != null) {
                          setState(() {
                            crpdFIle = value;
                            hasPickedImage = true;
                          });
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Attach image \n(optional)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGrayishBlueText,
                        textStyle: const TextStyle(fontSize: 12),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: isCreatingPost ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: kGrayishBlueText,
                      ),
                      child: !isCreatingPost
                          ? const Text("Create Post", style: TextStyle(fontSize: 12))
                          : const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
