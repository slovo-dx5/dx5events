import 'dart:convert';


import 'package:dx5veevents/widgets/profile_initials_widget.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../constants.dart';
import '../helpers/helper_widgets.dart';
import '../providers.dart';

import 'package:dio/dio.dart';

import 'dioServices/dioFetchService.dart';
import 'dioServices/dioPostService.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  XFile? _imageFile;
  String? imageID;

  // Function to pick an image from the device's gallery
  Future<XFile?> pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
        source: ImageSource.gallery); // or ImageSource.camera
    return pickedImage;
  }

  Future<MultipartFile> convertToMultipartFile(
      CroppedFile imageFile, ownerName) async {
    final fileExtension = imageFile.path.split('.').last;
    final file = imageFile.path;
    return MultipartFile.fromFile(
      file,
      filename: '$ownerName.$fileExtension', // Specify the file name
      contentType:
          MediaType("image", fileExtension), // Specify the content type
    );
  }

  Future<void> uploadImage(ownerName, ownerID) async {
    ///1.Upload picture to directus
    try {
      var pickedImage = await pickImage();
      if (pickedImage == null) return; // User canceled image selection
      CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedImage.path,
          aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.blue,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true),IOSUiSettings(title: 'Crop Image',)]

      );


      final imageFile = await convertToMultipartFile(croppedFile!, ownerName);

      final formData = FormData.fromMap({
        'folder': '4b5625d4-8ff7-4af0-bad2-caa451357e17',
        'title': imageFile, // The field name on the server
      });

      final response = await DioPostService().uploadProfilePic(formData);

      // Handle the response as needed
      print('Response: ${response.data}');

      Map<String, dynamic> jsonResponse =
      json.decode(json.encode(response.data));

// Extract the 'id' value
      setState(() {
        imageID = jsonResponse['data']['id'];
      });
      Map<String, dynamic> imageidDAta = {
        "profile_photo": imageID,

        // Add other key-value pairs as needed
      };

      ///Update user data
      ///
      print("owner id is $ownerID");
      final patchresponse=await DioFetchService().updateUserData(id: ownerID, body: imageidDAta);
      print('Patch Response: ${patchresponse.data}');

      print("image ID is $imageID");
    } catch (e) {
      if (e is DioError) {
        if (e.response != null) {
          print("image upload error is ${e.response!.data}");
        }
      }
      // Handle errors
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
                child: Center(
                    child: Padding(
                  padding: const EdgeInsets.only(left: 30.0, right: 30, top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (profileProvider.profileId == null ||
                          profileProvider.profileId == "")
                        const ProfileInitials(),
                      if (profileProvider.profileId != null &&
                          profileProvider.profileId != "")
                        const ProfilePicWidget(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: IconButton(
                            onPressed: () async {
                              await uploadImage(profileProvider.firstName,
                                  profileProvider.userID);
                              profileProvider.editProfile(newProfileId: imageID!);
                            },
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 40,
                            )),
                      )
                    ],
                  ),
                )),
              ),
              verticalSpace(height: 45),
              nameWidget(
                  name:
                      "${profileProvider.firstName} ${profileProvider.lastName}",
                  context: context,
                  phone: profileProvider.phone,
                  email: profileProvider.email, company: profileProvider.company,role: profileProvider.role),

              verticalSpace(height: 20),

            ],
          ),
        ),
      ),
    );
  }
}
