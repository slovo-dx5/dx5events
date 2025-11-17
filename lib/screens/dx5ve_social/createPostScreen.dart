import 'dart:convert';
import 'dart:io';
import 'package:dx5veevents/dioServices/dioPostService.dart';
import 'package:dx5veevents/screens/dx5ve_social/social_feed.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
//import 'package:googleapis/chat/v1.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';



import '../../constants.dart';
import '../../dioServices/dioFetchService.dart';
import '../../helpers/analytics_helper.dart';
import '../../helpers/helper_functions.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _postTextController=TextEditingController();
  String? firstName;
  String? lastName;
  XFile? _pickedImage;
  bool? hasPickedImage=false;
  int? userID;
  File? crpdFIle;
  bool isCreatingPost=false;
  String? imageID;

  @override
  void initState() {

    getUserDetails();
    super.initState();

  }
  Future<XFile?> pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
        source: ImageSource.gallery); // or ImageSource.camera
    if (pickedImage != null) {
      setState(() {
        _pickedImage = pickedImage;
      });
    }
    return pickedImage;
  }
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

  selectImage() async {
    // Picking the image using the ImagePicker
    var pickedImage = await pickImage();
    if (pickedImage == null) return;

    // Return the picked image as a File
    File imageFile = File(pickedImage.path);
    return imageFile;
  }
   uploadImage(ownerName, ownerID,File croppedFile) async {
    ///1.Upload picture to directus
    try {


      final imageFile = await convertToMultipartFile(croppedFile, ownerName);

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

      return imageID;


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
  getUserDetails()async{
    getStringPref(kFirstName).then((value) {
      setState(() {
        firstName=value;
        print("firt name is $firstName");
      });
    });getIntPref(kUserID).then((value) {
      setState(() {
        userID=value;
        print("useri d name is $userID");
      });
    });
    getStringPref(kLastName).then((value) {

      if(value==""){
        setState(() {
          lastName=".";
        });
      }else{
        setState(() {
          lastName=value;
          print("last name is $lastName");
        });
      }

    });

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
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.close)),Spacer(),
                      const Text(
                        "New Post",
                        style:
                            TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                      ),Spacer(),
                    ],
                  ),verticalSpace(height: 10),
                  _pickedImage != null
                      ? Image.file(
                    File(_pickedImage!.path),
                    width: 200,
                    height: 200,
                  )
                      : SizedBox(height: 20,),
                  verticalSpace(height: 10),
                  TextFormField(
                    keyboardType: TextInputType.multiline,
                    controller: _postTextController,
                    maxLines: null,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter some text';
                      }else if(value.length<15){
                        return "Your post must be at least 15 characters";
                      }
                      return null;
                    },

                    decoration: InputDecoration(
                      hintText: 'Your post goes here...',
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 60.0, horizontal: 10.0),
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
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async{
                          selectImage().then((value){
                            setState(() {
                              crpdFIle=value;

                                hasPickedImage=true;


                            });
                          });
                          // Add your onPressed logic here
                          print('Attach image button pressed');
                        },
                        icon: const Icon(Icons.camera_alt), // Camera icon
                        label: const Text('Attach image \n(optional)'),

                        style: ElevatedButton.styleFrom(
                          backgroundColor:kGrayishBlueText,
                          textStyle: const TextStyle(fontSize: 12),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 20.0), // Padding
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10.0), // Rounded corners
                          ),
                        ),
                      ),
                      ElevatedButton(onPressed: ()async{
                        if(_formKey.currentState?.validate()??false){
                          setState(() {
                            isCreatingPost=true;
                          });

                          if(hasPickedImage==true){

                            await   uploadImage(firstName,
                                  userID,crpdFIle!).then((value){
                                    setState(() {
                                      imageID=value;
                                    });

                            });
                          }
                          try{

                            await DioPostService().createSocialPost(body:
                            {
                              // "id": 1,
                              // "date_created": "2024-10-29T09:07:20.630Z",
                              "user_id": userID,
                              "picture_link": imageID??"no image",
                              "post_description": _postTextController.text,
                              //"likes": null,
                              //"Comments": null,
                              "user_name": "$firstName $lastName"
                            }
                            );
                            await Dx5veAnalytics().logdx5veEvent(eventName: "socialPostCreated");


                            Fluttertoast.showToast(msg: "Post created successfully");
                            setState(() {
                              isCreatingPost=false;
                              crpdFIle=null;

                            });
                            _postTextController.clear();
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) => SocialFeed()));
                          }catch(e){
                            Fluttertoast.showToast(
                                backgroundColor: kKeyRedBG,
                                msg: "Error:Check your internet and try again");


                          }

                        }
                      },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:kGrayishBlueText, // Text color
                          ),
                          child:!isCreatingPost? const Text("Create Post",style: TextStyle(fontSize: 12),):CircularProgressIndicator())
                    ],
                  )
                ],
              ),
            ),
          )),
    );
  }
}
