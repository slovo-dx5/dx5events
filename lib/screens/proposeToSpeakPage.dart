import 'dart:convert';
import 'dart:io';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';



import '../constants.dart';
import '../dioServices/dioPostService.dart';
import '../helpers/helper_functions.dart';
class ProposeToSpeakPage extends StatefulWidget {
  String eventID;
  String eventName;
   ProposeToSpeakPage({super.key,required this.eventID,required this.eventName});

  @override
  State<ProposeToSpeakPage> createState() => _ProposeToSpeakPageState();
}

class _ProposeToSpeakPageState extends State<ProposeToSpeakPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController companyController = TextEditingController();
  TextEditingController roleController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController workEmailController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController topicController = TextEditingController();
  TextEditingController topicController2 = TextEditingController();
  TextEditingController topicController3 = TextEditingController();
  TextEditingController reasonController = TextEditingController();
  TextEditingController linkedinController = TextEditingController();
  TextEditingController websiteController = TextEditingController();
  bool isEmail(String input) => EmailValidator.validate(input);
  bool isSubmitting=false;
  List <String> proposedTopics=[];


  XFile? _imageFile;
  File? _image;
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

   uploadImage(ownerName, ) async {
    ///1.Upload picture to directus
    try {
      var pickedImage = await pickImage();
      if (pickedImage == null) return; // User canceled image selection
      CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedImage.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.blue,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true),IOSUiSettings(title: 'Crop Image',)]

      ); setState(() {
        _image = File(croppedFile!.path!);
      });


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

  @override
  Widget build(BuildContext context) {
    return  SafeArea(
      child: Scaffold(body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(key: _formKey,
          child: SingleChildScrollView(
            child: Column(children: [
              RichText(
                text:  TextSpan(
                  style: const TextStyle(
                    fontSize: 16.0,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Contribute your knowledge and expertise as a speaker in The ${widget.eventName}. As a speaker you will get to: \n',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const TextSpan(
                      text: '\n• ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(style: TextStyle(fontSize: 11),
                      text: 'Grow your professional profile and brand as a thought leader\n• '
                        'Get direct access to connect with the right people, build relationships and learn from your peers.\n• '
                    'Attract new business opportunities by showcasing your work, knowledge and value.',
                    ),

                  ],
                ),
              ),verticalSpace(height: 10),
                         verticalSpace(height: 10),

              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: "First Name"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),              verticalSpace(height: 10),
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: "Last Name"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),verticalSpace(height: 10),   TextFormField(
                controller: workEmailController,
                decoration: const InputDecoration(labelText: "Work Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  } else if (!isEmail(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),              verticalSpace(height: 10),
              TextFormField(
                controller: companyController,
                decoration: const InputDecoration(labelText: "Company"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'The company you represent is required';
                  }
                  return null;
                },
              ),
              verticalSpace(height: 10),
              TextFormField(
                controller: roleController,
                decoration: const InputDecoration(labelText: "Role"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Your role is required';
                  }
                  return null;
                },
              ),              verticalSpace(height: 10),
              TextFormField(keyboardType: TextInputType.number,
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),              verticalSpace(height: 10),
              TextFormField(
                textCapitalization: TextCapitalization.sentences,
                controller: bioController, maxLines: null,
                decoration: const InputDecoration(labelText: "Bio",      contentPadding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 10.0),),

              ),verticalSpace(height: 20),
              GestureDetector(
                onTap: ()async {
                  await uploadImage("${firstNameController.text} ${lastNameController.text}");
                },
                child: Container(
                  padding: EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
                  height: 200.0,
                  child:  Center(
                    child: _image == null
                        ? Text(
                      "Profile Picture",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.0),
                    ):Image.file(_image!),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.only(top: 15,bottom: 15),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    const Text("Enter up to three topics you plan to talk about"),verticalSpace(height: 5),
                    TextFormField(
                      textCapitalization: TextCapitalization.sentences,
                      controller: topicController, maxLines: null,
                      decoration: const InputDecoration(labelText: "Proposed Topic",
                        contentPadding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 10.0),),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required';
                        }
                        return null;
                      },

                    ), verticalSpace(height: 10),TextFormField(
                      textCapitalization: TextCapitalization.sentences,
                      controller: topicController2, maxLines: null,
                      decoration: const InputDecoration(labelText: "Second Proposed Topic (Optional)",
                        contentPadding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 10.0),),

                    ),verticalSpace(height: 10), TextFormField(
                      textCapitalization: TextCapitalization.sentences,
                      controller: topicController3, maxLines: null,
                      decoration: const InputDecoration(labelText: "Third Proposed Topic (Optional)",
                        contentPadding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 10.0),),

                    ),
                  ],
                ),
              ),verticalSpace(height: 10),TextFormField(
                textCapitalization: TextCapitalization.sentences,
                controller: reasonController, maxLines: null,
                decoration: const InputDecoration(labelText: "Reason for proposed topics",      contentPadding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 10.0),),

              ),verticalSpace(height: 10),TextFormField(
                textCapitalization: TextCapitalization.sentences,
                controller: linkedinController, maxLines: null,
                decoration: const InputDecoration(labelText: "Linkedin profile link",      ),

              ),verticalSpace(height: 10),TextFormField(
                textCapitalization: TextCapitalization.sentences,
                controller: websiteController, maxLines: null,
                decoration: const InputDecoration(labelText: "Personal website (optional)",     ),

              ),verticalSpace(height: 20),
              
             Visibility(
               visible: isSubmitting==false,
               replacement: const SizedBox(height: 100,width: 100,child: SpinKitCircle(color: kCISOPurple,size: 50,),),
               child:  primaryButton2(context: context, onPressedFunction: ()async{
                 setState(() {
                   isSubmitting=true;
                 });
               proposedTopics.add(topicController.text);
               if(topicController2.text!=null || topicController2.text=="")proposedTopics.add(topicController2.text);
               if(topicController3.text!=null || topicController3.text=="")proposedTopics.add(topicController3.text);
               proposedTopics.add(topicController.text);

               await submitProposalToSPeak(firstName: firstNameController.text,
                   lastName: lastNameController.text, workEmail: workEmailController.text,
                   workPhone: phoneController.text,
                   company: companyController.text, role: roleController.text,
                   bio: bioController.text, linkedinProfileLink: linkedinController.text, eventId: '8',
                   reasonsForProposal: reasonController.text,
                   proposedTopics: proposedTopics, imageID: imageID!);

                 setState(() {
                   isSubmitting=false;
                 });
             }, buttonText: "SUBMIT PROPOSAL", backgroundColor: kPrimaryColor),),

              verticalSpace(height: 20)

            ],),
          ),
        ),
      ),),
    );
  }
}
