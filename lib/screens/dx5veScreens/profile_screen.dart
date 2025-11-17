import 'dart:convert';


import 'package:dx5veevents/widgets/profile_initials_widget.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';


import '../../../constants.dart';
import '../../../helpers/helper_widgets.dart';
import '../../../providers.dart';

import 'package:dio/dio.dart';

import '../../dioServices/dioFetchService.dart';
import '../../dioServices/dioPostService.dart';
import '../../helpers/analytics_helper.dart';
import '../../helpers/helper_functions.dart';


class ProfileScreen extends StatefulWidget {
  int eventId;

   ProfileScreen({super.key,required this.eventId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  String? imageID;
  String? qrURL;
  ProfileProvider? profileProvider;
  int ?recordId;
  // Function to pick an image from the device's gallery
  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider?.loadUserProfile();
      await Dx5veAnalytics().logdx5veEvent(eventName: "profilePageVisited");
// Ensure profile is loaded
      if (profileProvider?.userID != null) {
        fetchSingleAtendee(userid: profileProvider!.userID!);
      }
    });


    super.initState();
  }
  Future<XFile?> pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
        source: ImageSource.gallery); // or ImageSource.camera
    return pickedImage;
  }
  // Widget _buildQrCodeSection() {
  //   return Container(
  //     margin: const EdgeInsets.only(top: 16, bottom: 24),
  //     padding: const EdgeInsets.all(16),
  //     color: Colors.white,
  //     child: qrURL==null?CircularProgressIndicator():Column(
  //       children: [
  //         const Text(
  //           'My QR Code',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //
  //         // QR Code
  //         Center(
  //           child: CachedNetworkImage(
  //             fit: BoxFit.cover,
  //             imageUrl: qrURL!,
  //             progressIndicatorBuilder: (context, url, downloadProgress) =>
  //                 SizedBox(
  //                     height: 200,
  //                     width: 200,
  //                     child: CircularProgressIndicator(
  //                         value: downloadProgress.progress)),
  //             imageBuilder: (context, imageProvider) => SizedBox(
  //               height: 400,
  //               width: 400,
  //               child: ClipPath(
  //                 clipper: MyCustomClipper(), // Define your custom clipper
  //                 child: Container(
  //                   decoration: BoxDecoration(
  //                     image: DecorationImage(
  //                       image: imageProvider,
  //                       fit: BoxFit.cover,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //
  //         Text(
  //           'Scan to view my profile',
  //           style: TextStyle(
  //             color: Colors.grey[600],
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //
  //
  //       ],
  //     ),
  //   );
  // }

  Future<MultipartFile> convertToMultipartFile(
      File imageFile, ownerName) async {
    final fileExtension = imageFile.path.split('.').last;
    final file = imageFile.path;
    return MultipartFile.fromFile(
      file,
      filename: '$ownerName.$fileExtension', // Specify the file name
      contentType:
      MediaType("image", fileExtension), // Specify the content type
    );
  }

  fetchSingleAtendee({required int userid})async{
    final profileProvider = ProfileProvider().userID;
    var response = await DioFetchService().fetchSingleAttendeeForEvent(id: userid!, eventID: widget.eventId);
    var data = response.data["data"];
    setState(() {
      recordId=data[0]["id"];
      qrURL=data[0]["checkin_qr_code_jpeg_url"];
      print("qr code url is $qrURL");
    });
    print("record id is $recordId");

  }

  Future<void> uploadImage(ownerName, ownerID) async {
    ///1.Upload picture to directus
    try {
      var pickedImage = await pickImage();
      if (pickedImage == null) return; // User canceled image selection
      File? croppedFile = File(pickedImage.path);


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
      final patchresponse=await DioFetchService().updateUserData( body: imageidDAta, eventId: widget.eventId, recordid: recordId!);
      print('Patch Response: ${patchresponse.data}');
      UserPointsService().createOrUpdateUserPoints(userId: ownerID,actionId: 2);

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
    print("Profile id is ${profileProvider.profileId}");
    print("user id is ${profileProvider.userID}");

    return   SafeArea(
      child: Scaffold(
        backgroundColor:kProfileBlue,
        appBar: AppBar(
          title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.w600)),
          centerTitle: true,
          backgroundColor: kProfileBlue,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Profile Image Section
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: profileProvider.profileId != null &&
                        profileProvider.profileId!.isNotEmpty
                        ? NetworkImage(profileProvider.profileId!)
                        : null,
                    child: (profileProvider.profileId == null ||
                        profileProvider.profileId!.isEmpty)
                        ? Text(
                      "${profileProvider.firstName[0]}${profileProvider.lastName[0]}",
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.bold),
                    )
                        : null,
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () async {
                        await Dx5veAnalytics().logdx5veEvent(eventName: "profilePicUpdated");

                        await uploadImage(
                          profileProvider.firstName,
                          profileProvider.userID,
                        );
                        profileProvider.editProfile(newProfileId: imageID!);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueAccent,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Name and Role Section
              Text(
                "${profileProvider.firstName} ${profileProvider.lastName}",
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                profileProvider.role ?? "No role specified",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                profileProvider.company ?? "",
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w400, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // Contact Info Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: kProfileBlue,
                  borderRadius: BorderRadius.circular(16),

                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContactRow(Icons.email_outlined, profileProvider.email),
                    const Divider(height: 20),
                    _buildContactRow(Icons.phone_outlined, profileProvider.phone),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // QR Code Section
              _buildQrCodeSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String? text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text ?? "Not provided",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrCodeSection() {
    return Column(
      children: [
        const Text(
          "Your QR Code",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Icon(Icons.qr_code, size: 160, color: Colors.black87),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
class MyCustomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Create a crop that takes the center 80% of the image
    path.moveTo(size.width * 0.1, size.height * 0.1);
    path.lineTo(size.width * 0.9, size.height * 0.1);
    path.lineTo(size.width * 0.9, size.height * 0.9);
    path.lineTo(size.width * 0.1, size.height * 0.9);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}