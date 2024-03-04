// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:duwit/constants/constants.dart';
// import 'package:duwit/postEditing/editevents.dart';
// import 'package:duwit/postEditing/edithiring.dart';
// import 'package:duwit/screens/main_screens/full_eventpost.dart';
// import 'package:duwit/screens/main_screens/full_forhirepost.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:duwit/screens/main_screens/full_Hiring_post.dart';
// import 'package:duwit/home_flow/sidedrawer.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:geolocator/geolocator.dart';
//
// import 'package:timeago/timeago.dart' as timeago;
// import 'package:image_picker/image_picker.dart';
// import 'package:duwit/postEditing/editskill.dart';
//
// import 'dart:io';
// import 'package:path/path.dart' as Path;
//
// FirebaseAuth auth = FirebaseAuth.instance;
// var userid;
// //String userprofileid;
//
// class ProfilePage extends StatefulWidget {
//   //var userprofileid;
//   //ProfilePage({this.userprofileid});
//
//   @override
//   _ProfilePageState createState() => _ProfilePageState();
// }
//
// class _ProfilePageState extends State<ProfilePage> {
//   final Reference storageRef = FirebaseStorage.instance.ref();
//   var userhiringPosts;
//   File _image;
//   String newUsername;
//   BuildContext scaffoldContext;
//   Stream eventstream;
//   Stream hiringstream;
//   Stream forhirestream;
//   String postownerid;
//   var metersdistance;
//   var currentlatitude;
//   var currentlongitude;
//   Uri url;
//   // ignore: non_constant_identifier_names
//   String PostOrientation = "hiring";
//   final double circleRadius = 120.0;
//
//   TextEditingController usernameController = TextEditingController();
//
//   getImage() async {
//     PickedFile pickedfile =
//     await ImagePicker().getImage(source: ImageSource.gallery);
//     setState(() {
//       this._image = File(pickedfile.path);
//     });
//   }
//
//   Future<String> uploadImage(somefile) async {
//     String filename = Path.basename(_image.path);
//     Reference ref = storageRef.child(filename);
//     UploadTask uploadtask = ref.putFile(somefile);
//     String downloadUrl = await (await uploadtask).ref.getDownloadURL();
//     return downloadUrl;
//   }
//
//   Column buildCountColumn(String label, String count) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Text(
//           count.toString(),
//           style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
//         ),
//         Container(
//           margin: EdgeInsets.only(top: 4.0),
//           child: Text(
//             label,
//             style: TextStyle(
//                 color: Colors.grey,
//                 fontSize: 15.0,
//                 fontWeight: FontWeight.w400),
//           ),
//         )
//       ],
//     );
//   }
//
//   final _auth = FirebaseAuth.instance;
//   locatePosition() async {
//     final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.medium);
//
//     setState(() {
//       currentlatitude = position.latitude;
//       currentlongitude = position.longitude;
//     });
//   }
//
//   //Check for the users id from firestore
//   handledeletehiringpost(BuildContext parentcontext, var dbHiringID) {
//     return showDialog(
//         context: parentcontext,
//         builder: (context) {
//           return SimpleDialog(
//             title: Text(
//               "Delete this task?",
//             ),
//             children: [
//               SimpleDialogOption(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   deletehiringpost(dbHiringID);
//                 },
//                 child: Text(
//                   "Delete",
//                   style: TextStyle(color: Colors.blue),
//                 ),
//               ),
//               SimpleDialogOption(
//                 onPressed: () => Navigator.pop(context),
//                 child: Text(
//                   "Cancel",
//                   // style:  TextStyle(color:Colors.blue),
//                 ),
//               )
//             ],
//           );
//         });
//   }
//
//   handledeleteskillpost(BuildContext parentcontext, var dbSkillID) {
//     return showDialog(
//         context: parentcontext,
//         builder: (context) {
//           return SimpleDialog(
//             title: Text(
//               "Delete this post?",
//             ),
//             children: [
//               SimpleDialogOption(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   deleteskillpost(dbSkillID);
//                 },
//                 child: Text(
//                   "Delete",
//                   style: TextStyle(color: Colors.blue),
//                 ),
//               ),
//               SimpleDialogOption(
//                 onPressed: () => Navigator.pop(context),
//                 child: Text(
//                   "Cancel",
//                   // style:  TextStyle(color:Colors.blue),
//                 ),
//               )
//             ],
//           );
//         });
//   }
//
//   handledeleteeventpost(BuildContext parentcontext, var eventID) {
//     return showDialog(
//         context: parentcontext,
//         builder: (context) {
//           return SimpleDialog(
//             title: Text(
//               "Delete this post?",
//             ),
//             children: [
//               SimpleDialogOption(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   deleteeventpost(eventID);
//                 },
//                 child: Text(
//                   "Delete",
//                   style: TextStyle(color: Colors.blue),
//                 ),
//               ),
//               SimpleDialogOption(
//                 onPressed: () => Navigator.pop(context),
//                 child: Text(
//                   "Cancel",
//                   // style:  TextStyle(color:Colors.blue),
//                 ),
//               )
//             ],
//           );
//         });
//   }
//
//   deleteeventpost(var dbeventID) {
//     //delete the post itself
//     firestore
//         .collection("eventposts")
//         .doc(userid)
//         .collection("userEventPosts")
//         .doc(dbeventID)
//         .get()
//         .then((doc) {
//       if (doc.exists) {
//         doc.reference.delete();
//       }
//     });
//
//     //delete the post image
//     FirebaseStorage.instance.ref().child("post_$dbeventID.jpg").delete();
//   }
//
//   //done
//   deletehiringpost(var dbhiringID) {
//     //delete the post itself
//     firestore
//         .collection("hiringposts")
//         .doc(userid)
//         .collection("userHiringPosts")
//         .doc(dbhiringID)
//         .get()
//         .then((doc) {
//       if (doc.exists) {
//         doc.reference.delete();
//       }
//     });
//
//     //delete the post image
//     storageRef.child("post_$dbhiringID.jpg").delete();
//   }
//
//   deleteskillpost(var dbSkillID) {
//     //delete the post itself
//     firestore
//         .collection("forhireposts")
//         .doc(userid)
//         .collection("UserForHirePosts")
//         .doc(dbSkillID)
//         .get()
//         .then((doc) {
//       if (doc.exists) {
//         doc.reference.delete();
//       }
//     });
//
//     //delete the post image
//     storageRef.child("post_$dbSkillID.jpg").delete();
//   }
//   getdistance(
//       var postlat, var postlong, var postlocation, var ownerId, var hiringid) {
//     try {
//       metersdistance = Geolocator.distanceBetween(
//           currentlatitude, currentlongitude, postlat, postlong);
//
//       String meter = metersdistance.toStringAsFixed(0);
//       var kilometer = metersdistance / 1000;
//       String km = kilometer.toStringAsFixed(0);
//
//       return GestureDetector(
//         onTap: () async {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) =>
//               // Chat(futureHiringPostOwnerID: items["ownerId"] ,
//               FullHiringPost(
//                   futureHiringPostOwnerID: ownerId,
//                   futureHiringPostID: hiringid,
//                   currentuser: userid,
//                   distance:metersdistance,postlat:currentlatitude,postlong:currentlongitude),
//             ),
//           );
//         },
//         child: Container(
//           width: 100,
//           child: Row(
//             children: [
//               Expanded(
//                 child: postlocation != null
//                     ? Text(
//                   postlocation,
//                   style: TextStyle(fontSize: 10),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 )
//                     : Text(""),
//                 // child: Image.asset(
//                 //   "assets/images/distanceicon.png",
//                 //   color: Colors.white,
//                 //   height: 14,
//                 //   width: 30,
//                 // ),
//               ),
//               Expanded(
//                   child: metersdistance==null?Text(""):Text(
//                     metersdistance > 1000 ? "$km KM" : "$meter M",
//                     style: TextStyle(fontSize: 10),
//                   )),
//             ],
//           ),
//         ),
//       );
//     } catch (e) {
//       print("the error is $e");
//     }
//   }
//
//   hiringfooteritems(
//       var dbHiringID,
//       var dbhiringownerId,
//       var dbtitle,
//       var dbdescription,
//       var dbcurrency,
//       var dbbudget,
//       var dbspecial,
//       var dbpeople) {
//     //Check for the users id from firestore
//
//
//
//     return Row(
//       mainAxisSize: MainAxisSize.max,
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(left: 10, top: 20, right: 4),
//           child: Row(
//             children: [
//               GestureDetector(
//                 onTap: () async {
//                   try {
//                     DocumentReference ref = FirebaseFirestore.instance
//                         .collection('hiringposts')
//                         .doc(postownerid)
//                         .collection("userHiringPosts")
//                         .doc(dbHiringID);
//
//                     await ref.update({"active": false});
//                   } catch (e) {}
//                 },
//                 child: Text(
//                   "Mark as Complete",
//                   style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold),
//                 ),
//               ),
//               SizedBox(
//                 width: 5,
//               ),
//               Icon(
//                 Icons.sticky_note_2_outlined,
//                 size: 12,
//                 color: Colors.grey,
//               ),
//             ],
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.only(left: 10, top: 20, right: 4),
//           child: GestureDetector(
//             onTap: () async {
//               handledeletehiringpost(context, dbHiringID);
//             },
//             child: Row(
//               children: [
//                 Text(
//                   "Delete",
//                   style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(
//                   width: 3,
//                 ),
//                 Icon(
//                   Icons.delete,
//                   size: 12,
//                   color: Colors.grey,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.only(left: 10, top: 20, right: 4),
//           child: GestureDetector(
//             onTap: () async {
//               edithiringpost(dbhiringownerId, dbHiringID, dbtitle,
//                   dbdescription, dbcurrency, dbbudget, dbspecial, dbpeople);
//             },
//             child: Row(
//               children: [
//                 Text(
//                   "Edit Task",
//                   style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(
//                   width: 3,
//                 ),
//                 Icon(
//                   Icons.edit,
//                   size: 12,
//                   color: Colors.grey,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//     //dont show profile button to "not profile owner"
//   }
//
//   editskillpost(var ownerId, var skillpostid, var posttitle, var description,
//       var currency, var rate, var special) {
//     //step1
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) =>
//         // Chat(futureHiringPostOwnerID: items["ownerId"] ,
//         EditSkillPost(
//             futureSkillPostOwnerID: ownerId,
//             futureSkillPostID: skillpostid,
//             posttitle: posttitle,
//             postbudget: rate,
//             postcurrency: currency,
//             postdescription: description,
//             postspecial: special),
//       ),
//     );
//     //send post data to edit screen
//     //hiringposts>userid>userHiringposts>doc["postid"]
//
//     ///step2
//     //create textediting controllers for all fields
//     //set initial text for all fields from values sent from previous page
//     //fill text fields with text fields from firebase
//   }
//
//   skillfooteritems(var dbskillID, var dbskillownerId, var dbtitle,
//       var dbdescription, var dbcurrency, var dbbudget, var dbspecial) {
//     //Check for the users id from firestore
//
//     return Row(
//       mainAxisSize: MainAxisSize.max,
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(left: 10, top: 20, right: 4),
//           child: Row(
//             children: [
//               GestureDetector(
//                 onTap: () async {
//                   try {
//                     DocumentReference ref = FirebaseFirestore.instance
//                         .collection('forhireposts')
//                         .doc(postownerid)
//                         .collection("UserForHirePosts")
//                         .doc(dbskillID);
//
//                     await ref.update({"active": false});
//                   } catch (e) {}
//                 },
//                 child: Text(
//                   "Mark as Complete",
//                   style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold),
//                 ),
//               ),
//               SizedBox(
//                 width: 5,
//               ),
//               Icon(
//                 Icons.sticky_note_2_outlined,
//                 size: 15,
//                 color: Colors.grey,
//               ),
//             ],
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.only(
//             top: 20,
//           ),
//           child: GestureDetector(
//             onTap: () async {
//               handledeleteskillpost(context, dbskillID);
//             },
//             child: Row(
//               children: [
//                 Text(
//                   "Delete",
//                   style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(
//                   width: 5,
//                 ),
//                 Icon(
//                   Icons.delete,
//                   size: 15,
//                   color: Colors.grey,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.only(left: 10, top: 20, right: 4),
//           child: GestureDetector(
//             onTap: () async {
//               editskillpost(dbskillownerId, dbskillID, dbtitle, dbdescription,
//                   dbcurrency, dbbudget, dbspecial);
//             },
//             child: Row(
//               children: [
//                 Text(
//                   "Edit Task",
//                   style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(
//                   width: 3,
//                 ),
//                 Icon(
//                   Icons.edit,
//                   size: 12,
//                   color: Colors.grey,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//     //dont show profile button to "not profile owner"
//   }
//
//   edithiringpost(var ownerId, var hiringpostid, var posttitle, var description,
//       var currency, var budget, var special, var people) {
//     //step1
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) =>
//         // Chat(futureHiringPostOwnerID: items["ownerId"] ,
//         EditHiringPost(
//             futureHiringPostOwnerID: ownerId,
//             futureHiringPostID: hiringpostid,
//             currentuser: userid,
//             posttitle: posttitle,
//             postpeople: people,
//             postbudget: budget,
//             postcurrency: currency,
//             postdescription: description,
//             postspecial: special),
//       ),
//     );
//     //send post data to edit screen
//     //hiringposts>userid>userHiringposts>doc["postid"]
//
//     ///step2
//     //create textediting controllers for all fields
//     //set initial text for all fields from values sent from previous page
//     //fill text fields with text fields from firebase
//   }
//   editeventpost(var ownerId, var eventpostid, var posttitle, var description,
//       var special,  var people, bool isRequest) {
//     //step1
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) =>
//         // Chat(futureHiringPostOwnerID: items["ownerId"] ,
//         EditEventPost(
//             futureEventPostOwnerID: ownerId,
//             futureEventPostID: eventpostid,
//             posttitle: posttitle,
//             postdescription: description,
//             postspecial: special,
//             isRequest:isRequest
//         ),
//       ),
//     );
//
//   }
//
//   eventfooteritems(var dbEventID, var dbownerId,var title, var description,var special, var people, bool isRequest) {
//     //Check for the users id from firestore
//
//
//     return Row(
//       mainAxisSize: MainAxisSize.max,
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(left: 10, top: 20, right: 4),
//           child: Row(
//             children: [
//               GestureDetector(
//                 onTap: () async {
//                   try {
//                     DocumentReference ref = FirebaseFirestore.instance
//                         .collection('eventposts')
//                         .doc(postownerid)
//                         .collection("userEventPosts")
//                         .doc(dbEventID);
//
//                     await ref.update({"active": false});
//                   } catch (e) {}
//                 },
//                 child: Text(
//                   "Mark as Complete",
//                   style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold),
//                 ),
//               ),
//               SizedBox(
//                 width: 5,
//               ),
//               Icon(
//                 Icons.sticky_note_2_outlined,
//                 size: 15,
//                 color: Colors.grey,
//               ),
//             ],
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.only(top: 20),
//           child: GestureDetector(
//             onTap: () async {
//               handledeleteeventpost(context, dbEventID);
//             },
//             child: Row(
//               children: [
//                 Text(
//                   "Delete",
//                   style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(
//                   width: 5,
//                 ),
//                 Icon(
//                   Icons.delete,
//                   size: 15,
//                   color: Colors.grey,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.only(left: 10, top: 20, right: 4),
//           child: GestureDetector(
//             onTap: () async {
//               editeventpost(dbownerId, dbEventID, title,
//                 description, special,people, isRequest, );
//             },
//             child: Row(
//               children: [
//                 Text(
//                   "Edit",
//                   style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(
//                   width: 3,
//                 ),
//                 Icon(
//                   Icons.edit,
//                   size: 12,
//                   color: Colors.grey,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//     //dont show profile button to "not profile owner"
//
//   }
//
//   Future<String> getCurrentUID() async {
//     return userid = (_auth.currentUser).uid;
//     // setState(() {
//     //   userid=_auth.currentUser.uid;
//     // });
//   }
//
//   createdynamiclink() async {
//     DynamicLinkParameters parameters = DynamicLinkParameters(
//         uriPrefix: "https://getduwit.page.link",
//         link: Uri.parse("https://getduwit.page.link/mVFa"),
//         androidParameters: AndroidParameters(
//             packageName: "com.slovo.duwit", minimumVersion: 0),
//         socialMetaTagParameters: SocialMetaTagParameters(
//             title: "Duwit: Get paid for anything you can do"));
//     final ShortDynamicLink shortlink = await parameters.buildShortLink();
//     setState(() {
//       url = shortlink.shortUrl;
//     });
//     return url;
//   }
//
//   //done
//
//   submit() async {
//     final User user = _auth.currentUser;
//     String mediaUrl = await uploadImage(_image);
//
//     try {
//       DocumentReference ref =
//       FirebaseFirestore.instance.collection('users').doc(user.uid);
//
//       ref.update({"MediaURL": mediaUrl});
//     } catch (e) {}
//     //     .set({
//     //   'MediaURL': mediaUrl
//     // },SetOptions(merge: true));
//   }
//
//   //AuthService editprofileobj = new AuthService();
//
//   Future<bool> editprofile(BuildContext context) {
//     // Navigator.pushNamed(context, '/editprofile');
//     scaffoldContext = context;
//     void createSnackBar(String message) {
//       final snackBar = new SnackBar(
//         content: new Text(message),
//       );
//
//       // Find the Scaffold in the Widget tree and use it to show a SnackBar!
//       ScaffoldMessenger.of(context).showSnackBar(snackBar);
//     }
//
//     return showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: Text("Edit Profile"),
//             content: SingleChildScrollView(
//               child: Column(
//                 children: <Widget>[
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Align(
//                         alignment: Alignment.center,
//                         child: CircleAvatar(
//                           radius: 60,
//                           child: ClipOval(
//                             child: SizedBox(
//                               width: 150,
//                               height: 150,
//                               child:
//                               //buildShowImage()
//                               (_image != null)
//                                   ? Image.file(
//                                 _image,
//                                 fit: BoxFit.fill,
//                               )
//                                   : Image(
//                                 image: AssetImage(
//                                     "assets/images/blank-profile-picture-973460_640.png"),
//                                 fit: BoxFit.fill,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       Padding(
//                         padding: EdgeInsets.only(top: 20),
//                         child: IconButton(
//                           icon: Icon(Icons.camera_alt_outlined),
//                           onPressed: () {
//                             getImage();
//                           },
//                         ),
//                       )
//                     ],
//                   ),
//                   SizedBox(
//                     height: 20.0,
//                   )
//                 ],
//               ),
//             ),
//             actions: <Widget>[
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(right: 20),
//                     child: TextButton(
//                       child: Text(
//                         "Cancel",
//                         style: TextStyle(color: Colors.white),
//                       ),
//                       style: ButtonStyle(
//                           backgroundColor:
//                           MaterialStateProperty.all(Colors.blue)),
//                       onPressed: () {
//                         Navigator.of(context).pop();
//                       },
//                     ),
//                   ),
//                   TextButton(
//                     child: Text(
//                       "Update",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                     style: ButtonStyle(
//                         backgroundColor:
//                         MaterialStateProperty.all(Colors.blue)),
//                     onPressed: () async {
//                       if (_image != null) {
//                         submit();
//                       }
//
//                       //editformKey.currentState.save();
//
//                       Navigator.of(context).pop();
//
//                       createSnackBar("Updated Successfully");
//                       await getUserInfo();
//                     },
//                   ),
//                 ],
//               )
//             ],
//           );
//         });
//   }
//
//   buildProfileButton() {
//     //if user is on their own profile, return edit profile button
//     // return Text("Edit");
//     //bool isProfileOwner = userid == widget.userprofileid;
//     // if (isProfileOwner) {
//     return TextButton(
//       child: Text(
//         "Edit Profile",
//         style: TextStyle(color: Colors.white),
//       ),
//       style: ButtonStyle(
//           backgroundColor: MaterialStateProperty.all(Colors.blue),
//           shape: MaterialStateProperty.all(
//             RoundedRectangleBorder(
//                 side: BorderSide(
//                   //color: Colors.white,
//                     width: 1,
//                     style: BorderStyle.solid),
//                 borderRadius: BorderRadius.circular(30)),
//           )),
//       onPressed: () {
//         editprofile(
//           context,
//         );
//       },
//     );
//   }
//
// //Function to get user data from firestore DB
//   Future<DocumentSnapshot> getUserInfo() async {
//     return await FirebaseFirestore.instance
//         .collection("users")
//         .doc(userid)
//         .get();
//   }
//
//   @override
//   void initState() {
//     getCurrentUID();
//     locatePosition();
//     super.initState();
//     hiringstream = FirebaseFirestore.instance
//         .collection("hiringposts")
//         .doc(userid)
//         .collection("userHiringPosts")
//         .snapshots();
//     // .snapshots();
//
//     forhirestream = FirebaseFirestore.instance
//         .collection("forhireposts")
//         .doc(userid)
//         .collection("UserForHirePosts")
//         .snapshots();
//
//     eventstream = FirebaseFirestore.instance
//         .collection("eventposts")
//         .doc(userid)
//         .collection("userEventPosts")
//         .snapshots();
//
//     // profileid();
//   }
//
//   hiringpostsview() {
//     return Column(
//       children: [
//         StreamBuilder(
//             stream: hiringstream,
//             builder: (context, AsyncSnapshot snapshots) {
//               if (snapshots.hasData) {
//                 if (snapshots.data.docs.length == 0) {
//                   return Center(
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 25),
//                       child: Container(
//                         //color: UniversalVariables.separatorColor,
//                         padding:
//                         EdgeInsets.symmetric(vertical: 35, horizontal: 25),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: <Widget>[Text("You have no posts")],
//                         ),
//                       ),
//                     ),
//                   );
//                 }
//                 return ListView.builder(
//                   //scrollDirection: Axis.vertical,
//                   physics: const NeverScrollableScrollPhysics(),
//                   shrinkWrap: true,
//                   itemCount: snapshots.data.docs.length,
//                   itemBuilder: (context, i) {
//                     DocumentSnapshot items = snapshots.data.docs[i];
//                     subtitleText() {
//                       if (items["MediaURL"] != null) {
//                         return Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Image.network(
//                             items["MediaURL"],
//                             width: MediaQuery.of(context).size.width,
//                             fit: BoxFit.cover,
//
//                             //  fit: BoxFit.fitWidth,
//                           ),
//                         );
//                       } else {
//                         return Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: Text(items["description"]),
//                         );
//                       }
//                     }
//
//                     //get post owner
//                     postownerid = items["ownerId"];
//
//                     getTime() {
//                       Timestamp timestamp = items['timestamp'];
//                       return Text(timeago
//                           .format(
//                           DateTime.tryParse(timestamp.toDate().toString()))
//                           .toString());
//                     }
//
//                     Future<DocumentSnapshot> getUserInfo() async {
//                       return await FirebaseFirestore.instance
//                           .collection("users")
//                           .doc(postownerid)
//                           .get();
//                     }
//
//                     return Column(
//                       children: [
//                         Container(
//                           decoration: BoxDecoration(
//                             border: Border.all(color: kLightText),
//                             borderRadius: BorderRadius.circular(10),
//                             color: kLightBG,
//                           ),
//                           child: Column(
//                             children: [
//                               ListTile(
//                                 leading: FutureBuilder(
//                                     future: getUserInfo(),
//                                     builder: (context,
//                                         AsyncSnapshot<DocumentSnapshot>
//                                         imagesnapshot) {
//                                       if (imagesnapshot.connectionState ==
//                                           ConnectionState.done) {
//                                         return CircleAvatar(
//                                           radius: 30,
//                                           // backgroundColor: Colors.grey,
//                                           backgroundImage: (imagesnapshot
//                                               .data["MediaURL"] !=
//                                               null)
//                                               ? NetworkImage(imagesnapshot
//                                               .data["MediaURL"])
//                                               : AssetImage(
//                                               "assets/images/blank-profile-picture-973460_640.png"),
//                                         );
//                                       }
//                                       return CircularProgressIndicator();
//                                     }),
//                                 title: GestureDetector(
//                                   child: Text(
//                                     '${items['postOwner']}',
//                                     style:
//                                     TextStyle(fontWeight: FontWeight.bold),
//                                   ),
//                                 ),
//                                 subtitle: getTime(),
//                                 trailing: Padding(
//                                   padding: const EdgeInsets.only(
//                                       top: 13.0),
//                                   child: Column(
//                                     children: [
//                                       Text(
//                                         items["currency"] +
//                                             " " +
//                                             items["budget"],
//                                         style: TextStyle(
//                                             color: Colors.red[300],
//                                             fontWeight:
//                                             FontWeight.bold,
//                                             fontSize: 10
//                                           //color: Color(0XFF90CAF9),
//                                         ),
//                                       ),
//                                       Padding(
//                                         padding:
//                                         const EdgeInsets.only(
//                                             top: 10.0),
//                                       ),
//                                       getdistance(
//                                         items["postLat"],
//                                         items["postLong"],
//                                         items["postLocation"],
//                                         items["ownerId"],
//                                         items["hiringPostID"],
//                                       )==null?Text("locating"):getdistance(
//                                         items["postLat"],
//                                         items["postLong"],
//                                         items["postLocation"],
//                                         items["ownerId"],
//                                         items["hiringPostID"],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 // trailing: IconButton(
//                                 //
//                                 //   icon: Icon(Icons.more_vert),
//                                 // ),
//                               ),
//                               ListTile(
//                                 title: Text(
//                                   items["title"],
//                                 ),
//                               ),
//                               Stack(
//                                 alignment: Alignment.center,
//                                 children: <Widget>[
//                                   GestureDetector(
//                                     onTap: () async {
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) =>
//                                           // Chat(futureHiringPostOwnerID: items["ownerId"] ,
//                                           FullHiringPost(
//                                               futureHiringPostOwnerID: items["ownerId"],
//                                               futureHiringPostID:items["hiringPostID"],
//                                               currentuser: userid,
//                                               distance:metersdistance,postlat:currentlatitude,postlong:currentlongitude),
//                                         ),
//                                       );
//                                     },
//                                     child: subtitleText(),
//                                   ),
//                                 ],
//                               ),
//                               hiringfooteritems(
//                                   items["hiringPostID"],
//                                   items["ownerId"],
//                                   items["title"],
//                                   items["description"],
//                                   items["currency"],
//                                   items["budget"],
//                                   items["specialRequirements"] == null
//                                       ? " "
//                                       : items["specialRequirements"],
//                                   items["Number of people"]),
//                               SizedBox(
//                                 height: 40,
//                               )
//                             ],
//                           ),
//                         ),
//                         SizedBox(
//                           height: 20,
//                         )
//                       ],
//                     );
//                   },
//                 );
//               }
//
//               return Center(child: CircularProgressIndicator());
//             }),
//       ],
//     );
//   }
//
//   skillpostsview() {
//     return Column(
//       children: [
//         StreamBuilder(
//             stream: forhirestream,
//             builder: (context, snapshot) {
//               if (snapshot.hasData) {
//                 if (snapshot.data.docs.length == 0) {
//                   return Center(
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 25),
//                       child: Container(
//                         //color: UniversalVariables.separatorColor,
//                         padding:
//                         EdgeInsets.symmetric(vertical: 35, horizontal: 25),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: <Widget>[Text("You have no posts")],
//                         ),
//                       ),
//                     ),
//                   );
//                 }
//                 return ListView.builder(
//                   //scrollDirection: Axis.vertical,
//                   physics: const NeverScrollableScrollPhysics(),
//                   shrinkWrap: true,
//                   itemCount: snapshot.data.docs.length,
//                   itemBuilder: (context, i) {
//                     DocumentSnapshot items = snapshot.data.docs[i];
//                     subtitleText() {
//                       if (items["MediaURL"] != null) {
//                         return Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Image.network(
//                             items["MediaURL"],
//                             width: MediaQuery.of(context).size.width,
//                             fit: BoxFit.cover,
//
//                             //  fit: BoxFit.fitWidth,
//                           ),
//                         );
//                       } else {
//                         return Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: Text(items["description"]),
//                         );
//                       }
//                     }
//
//                     //get post owner
//                     postownerid = items["ownerId"];
//
//                     getTime() {
//                       Timestamp timestamp = items['timestamp'];
//                       return Text(timeago
//                           .format(
//                           DateTime.tryParse(timestamp.toDate().toString()))
//                           .toString());
//                     }
//
//                     Future<DocumentSnapshot> getUserInfo() async {
//                       return await FirebaseFirestore.instance
//                           .collection("users")
//                           .doc(postownerid)
//                           .get();
//                     }
//
//                     return Column(
//                       children: [
//                         Container(
//                           decoration: BoxDecoration(
//                             border: Border.all(color: kLightText),
//                             borderRadius: BorderRadius.circular(10),
//                             color: kLightBG,
//                           ),
//                           child: Column(
//                             children: [
//                               ListTile(
//                                 leading: FutureBuilder(
//                                     future: getUserInfo(),
//                                     builder: (context,
//                                         AsyncSnapshot<DocumentSnapshot>
//                                         imagesnapshot) {
//                                       if (imagesnapshot.connectionState ==
//                                           ConnectionState.done) {
//                                         return CircleAvatar(
//                                           radius: 30,
//                                           // backgroundColor: Colors.grey,
//                                           backgroundImage: (imagesnapshot
//                                               .data["MediaURL"] !=
//                                               null)
//                                               ? NetworkImage(imagesnapshot
//                                               .data["MediaURL"])
//                                               : AssetImage(
//                                               "assets/images/blank-profile-picture-973460_640.png"),
//                                         );
//                                       }
//                                       return CircularProgressIndicator();
//                                     }),
//                                 title: GestureDetector(
//                                   child: Text(
//                                     '${items['postOwner']}',
//                                     style:
//                                     TextStyle(fontWeight: FontWeight.bold),
//                                   ),
//                                 ),
//                                 subtitle: getTime(),
//                                 trailing:Padding(
//                                   padding: const EdgeInsets.only(top:13.0),
//                                   child: Column(
//                                     children: [
//                                       SizedBox(height: 5,),
//                                       Text(
//                                         items["Currency"] +
//                                             " " +
//                                             items["Rate"],
//                                         style: TextStyle(
//                                             color: Colors.red[300],
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 12
//                                           //color: Color(0XFF90CAF9),
//                                         ),
//                                       ),
//                                       Padding(padding: const EdgeInsets.only(top:10.0),),
//                                       getdistance(items["postLat"], items["postLong"],items["postLocation"],items[
//                                       "ownerId"],items
//                                       [
//                                       "forHirePostID"],)==null?Text("Locating"):getdistance(items["postLat"], items["postLong"],items["postLocation"],items[
//                                       "ownerId"],items
//                                       [
//                                       "forHirePostID"],),
//                                     ],
//                                   ),
//                                 ),
//                                 // trailing: IconButton(
//                                 //
//                                 //   icon: Icon(Icons.more_vert),
//                                 // ),
//                               ),
//                               ListTile(
//                                 title: Text(
//                                   items["title"],
//                                 ),
//                               ),
//                               Stack(
//                                 alignment: Alignment.center,
//                                 children: <Widget>[
//                                   GestureDetector(
//                                     onTap: () async {
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) =>
//                                           // Chat(futureHiringPostOwnerID: items["ownerId"] ,
//                                           FullForHirePost(
//                                               futureHiringPostOwnerID:
//                                               items["ownerId"],
//                                               futureHiringPostID:
//                                               items["forHirePostID"],
//                                               currentuser: userid),
//                                         ),
//                                       );
//                                     },
//                                     child: subtitleText(),
//                                   ),
//                                 ],
//                               ),
//                               skillfooteritems(
//                                   items["forHirePostID"],
//                                   items["postOwner"],
//                                   items["title"],
//                                   items["description"],
//                                   items["Currency"],
//                                   items["Rate"],
//                                   items["Additional Information"]),
//                               SizedBox(
//                                 height: 20,
//                               )
//                             ],
//                           ),
//                         ),
//                         SizedBox(
//                           height: 20,
//                         )
//                       ],
//                     );
//                   },
//                 );
//               } else if (!snapshot.hasData) {
//                 // got data from snapshot but it is empty
//
//                 return Center(
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 25),
//                     child: Container(
//                       //color: UniversalVariables.separatorColor,
//                       padding:
//                       EdgeInsets.symmetric(vertical: 35, horizontal: 25),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: <Widget>[Text("You have no posts")],
//                       ),
//                     ),
//                   ),
//                 );
//               }
//
//               return Center(child: CircularProgressIndicator());
//             }),
//       ],
//     );
//   }
//
//   eventpostsview() {
//     return Column(
//       children: [
//         StreamBuilder(
//             stream: eventstream,
//             builder: (context, snapshot) {
//               if (snapshot.hasData) {
//                 if (snapshot.data.docs.length == 0) {
//                   return Center(
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 25),
//                       child: Container(
//                         //color: UniversalVariables.separatorColor,
//                         padding:
//                         EdgeInsets.symmetric(vertical: 35, horizontal: 25),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: <Widget>[Text("You have no posts")],
//                         ),
//                       ),
//                     ),
//                   );
//                 }
//                 return ListView.builder(
//                   //scrollDirection: Axis.vertical,
//                   physics: const NeverScrollableScrollPhysics(),
//                   shrinkWrap: true,
//                   itemCount: snapshot.data.docs.length,
//                   itemBuilder: (context, i) {
//                     DocumentSnapshot items = snapshot.data.docs[i];
//                     subtitleText() {
//                       if (items["MediaURL"] != null) {
//                         return Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Image.network(
//                             items["MediaURL"],
//                             width: MediaQuery.of(context).size.width,
//                             fit: BoxFit.cover,
//
//                             //  fit: BoxFit.fitWidth,
//                           ),
//                         );
//                       } else {
//                         return Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: Text(items["description"]),
//                         );
//                       }
//                     }
//
//                     //get post owner
//                     String postownerid = items["ownerId"];
//
//                     getTime() {
//                       Timestamp timestamp = items['timestamp'];
//                       return Text(timeago
//                           .format(
//                           DateTime.tryParse(timestamp.toDate().toString()))
//                           .toString());
//                     }
//
//                     Future<DocumentSnapshot> getUserInfo() async {
//                       return await FirebaseFirestore.instance
//                           .collection("users")
//                           .doc(postownerid)
//                           .get();
//                     }
//
//                     return Column(
//                       children: [
//                         Container(
//                           decoration: BoxDecoration(
//                             border: Border.all(color: kLightText),
//                             borderRadius: BorderRadius.circular(10),
//                             color: kLightBG,
//                           ),
//                           child: Column(
//                             children: [
//                               ListTile(
//                                   leading: FutureBuilder(
//                                       future: getUserInfo(),
//                                       builder: (context,
//                                           AsyncSnapshot<DocumentSnapshot>
//                                           imagesnapshot) {
//                                         if (imagesnapshot.connectionState ==
//                                             ConnectionState.done) {
//                                           return CircleAvatar(
//                                             radius: 30,
//                                             // backgroundColor: Colors.grey,
//                                             backgroundImage: (imagesnapshot
//                                                 .data["MediaURL"] !=
//                                                 null)
//                                                 ? NetworkImage(imagesnapshot
//                                                 .data["MediaURL"])
//                                                 : AssetImage(
//                                                 "assets/images/blank-profile-picture-973460_640.png"),
//                                           );
//                                         }
//                                         return CircularProgressIndicator();
//                                       }),
//                                   title: GestureDetector(
//                                     child: Text(
//                                       '${items['postOwner']}',
//                                       style:
//                                       TextStyle(fontWeight: FontWeight.bold),
//                                     ),
//                                   ),
//                                   subtitle: getTime(),
//                                   trailing: Padding(
//                                     padding:
//                                     const EdgeInsets.only(
//                                         top: 13.0),
//                                     child: Column(
//                                       children: [
//                                         items['isRequest'] == true
//                                             ? Text(
//                                           "Request",
//                                           style: TextStyle(
//                                               color: Colors
//                                                   .red[300],
//                                               fontWeight:
//                                               FontWeight
//                                                   .bold,
//                                               fontSize: 12),
//                                         )
//                                             : Text(
//                                           "Offer",
//                                           style: TextStyle(
//                                               color: Colors
//                                                   .green[
//                                               200],
//                                               fontSize: 12,
//                                               fontWeight:
//                                               FontWeight
//                                                   .bold),
//                                         ),
//                                         Padding(
//                                           padding:
//                                           const EdgeInsets
//                                               .only(
//                                               top: 10.0),
//                                         ),
//                                         getdistance(
//                                             items["postLat"],
//                                             items["postLong"],
//                                             items["postLocation"],
//                                             items["ownerId"],
//                                             items["eventPostID"])==null?Text("loading"):getdistance(
//                                             items["postLat"],
//                                             items["postLong"],
//                                             items["postLocation"],
//                                             items["ownerId"],
//                                             items["eventPostID"])
//                                       ],
//                                     ),
//                                   )
//                                 // trailing: IconButton(
//                                 //
//                                 //   icon: Icon(Icons.more_vert),
//                                 // ),
//                               ),
//                               ListTile(
//                                 title: Text(
//                                   items["title"],
//                                 ),
//                               ),
//                               Stack(
//                                 alignment: Alignment.center,
//                                 children: <Widget>[
//                                   GestureDetector(
//                                     onTap: () async {
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) =>
//                                           // Chat(futureHiringPostOwnerID: items["ownerId"] ,
//                                           FullEventPost(
//                                               futureHiringPostOwnerID:
//                                               items["ownerId"],
//                                               futureHiringPostID:
//                                               items["eventPostID"],
//                                               currentuser: userid),
//                                         ),
//                                       );
//                                     },
//                                     child: subtitleText(),
//                                   ),
//                                 ],
//                               ),
//                               eventfooteritems(
//                                   items["eventPostID"],
//                                   items["ownerId"],
//                                   items["title"],
//                                   items["description"],
//                                   items["specialRequirements"],
//                                   items["Number of People"],
//                                   items["isRequest"]
//                               ),
//                               SizedBox(
//                                 height: 20,
//                               )
//                             ],
//                           ),
//                         ),
//                         SizedBox(
//                           height: 20,
//                         )
//                       ],
//                     );
//                   },
//                 );
//               } else if (!snapshot.hasData) {
//                 // got data from snapshot but it is empty
//
//                 return Center(
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 25),
//                     child: Container(
//                       //color: UniversalVariables.separatorColor,
//                       padding:
//                       EdgeInsets.symmetric(vertical: 35, horizontal: 25),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: <Widget>[Text("You have no posts")],
//                       ),
//                     ),
//                   ),
//                 );
//               }
//
//               return Center(child: CircularProgressIndicator());
//             }),
//       ],
//     );
//   }
//
//   buildprofileposts() {
//     if (PostOrientation == "hiring") {
//       return hiringpostsview();
//     } else if (PostOrientation == "skills") {
//       return skillpostsview();
//     } else if (PostOrientation == "requests") {
//       return eventpostsview();
//     }
//   }
//
//   // ignore: non_constant_identifier_names
//   setPostOrientation(String PostOrientation) {
//     setState(() {
//       this.PostOrientation = PostOrientation;
//     });
//   }
//
//   //final _auth = FirebaseAuth.instance;
//   final firestore = FirebaseFirestore.instance;
//
//   @override
//   Widget build(context) {
//     return DefaultTabController(
//       length: 3,
//       initialIndex: 0,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text("Profile"),
//           centerTitle: true,
//         ),
//         drawer: SideDrawer(),
//         body: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ListView(
//                 physics: const NeverScrollableScrollPhysics(),
//
//                 shrinkWrap: true,
//                 //physics: NeverScrollableScrollPhysics(),
//                 children: [
//                   Column(
//                     children: <Widget>[
//                       Container(
//                         //height: 300,
//                         child: Column(
//                           children: <Widget>[
//                             Row(
//                               children: [
//                                 FutureBuilder(
//                                     future: getUserInfo(),
//                                     builder: (context,
//                                         AsyncSnapshot<DocumentSnapshot>
//                                         imagesnapshot) {
//                                       getTime() {
//                                         Timestamp timestamp =
//                                         imagesnapshot.data['timestamp'];
//                                         return Text(
//                                             timeago
//                                                 .format(DateTime.tryParse(
//                                                 timestamp
//                                                     .toDate()
//                                                     .toString()))
//                                                 .toString(),
//                                             style: TextStyle(
//                                                 color: Colors.grey,
//                                                 fontSize: 15.0,
//                                                 fontWeight: FontWeight.w400));
//                                       }
//
//                                       if (imagesnapshot.connectionState ==
//                                           ConnectionState.done) {
//                                         return Flexible(
//                                           child: Container(
//                                             height: MediaQuery.of(context)
//                                                 .size
//                                                 .height *
//                                                 0.50,
//                                             width: double.infinity,
//                                             // color: Color(0xffE0E0E0),
//                                             child: Stack(children: <Widget>[
//                                               Padding(
//                                                 padding:
//                                                 const EdgeInsets.all(16.0),
//                                                 child: Stack(
//                                                   alignment:
//                                                   Alignment.topCenter,
//                                                   children: <Widget>[
//                                                     Padding(
//                                                       padding: EdgeInsets.only(
//                                                         top: circleRadius / 2.0,
//                                                       ),
//
//                                                       ///here we create space for the circle avatar to get ut of the box
//                                                       child: Container(
//                                                         height: 300.0,
//                                                         decoration:
//                                                         BoxDecoration(
//                                                           borderRadius:
//                                                           BorderRadius
//                                                               .circular(
//                                                               15.0),
//                                                           // color: Colors.white,
//                                                           color:
//                                                           Color(0xff272c35),
//
//                                                           boxShadow: [
//                                                             BoxShadow(
//                                                               color: Colors
//                                                                   .black26,
//                                                               blurRadius: 8.0,
//                                                               offset: Offset(
//                                                                   0.0, 5.0),
//                                                             ),
//                                                           ],
//                                                         ),
//                                                         width: double.infinity,
//                                                         child: Padding(
//                                                             padding:
//                                                             const EdgeInsets
//                                                                 .only(
//                                                                 top: 15.0,
//                                                                 bottom:
//                                                                 15.0),
//                                                             child:
//                                                             SingleChildScrollView(
//                                                               child: Column(
//                                                                 children: <
//                                                                     Widget>[
//                                                                   SizedBox(
//                                                                     height:
//                                                                     circleRadius /
//                                                                         2,
//                                                                   ),
//                                                                   Container(
//                                                                     //padding: const EdgeInsets.only(left: 120,),
//                                                                     // padding: const EdgeInsets.symmetric(horizontal: 50),
//                                                                       child: FutureBuilder(
//                                                                           future: getUserInfo(),
//                                                                           builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
//                                                                             if (snapshot.connectionState ==
//                                                                                 ConnectionState.done) {
//                                                                               return ListView.builder(
//                                                                                   physics: const NeverScrollableScrollPhysics(),
//                                                                                   shrinkWrap: true,
//                                                                                   itemCount: 1,
//                                                                                   itemBuilder: (BuildContext context, int index) {
//                                                                                     return Center(
//                                                                                       child: Row(
//                                                                                         mainAxisAlignment: MainAxisAlignment.center,
//                                                                                         children: [
//                                                                                           Text(
//                                                                                             snapshot.data["username"],
//                                                                                             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 34.0),
//                                                                                           ),
//                                                                                           snapshot.data['isPro'] == true
//                                                                                               ? Flexible(
//                                                                                             child: Container(
//                                                                                               height: 15,
//                                                                                               width: 33,
//                                                                                               child: Center(
//                                                                                                   child: Text(
//                                                                                                     "PRO",
//                                                                                                     style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
//                                                                                                   )),
//                                                                                               decoration: BoxDecoration(color: kGoldColor, borderRadius: BorderRadius.circular(4)),
//                                                                                             ),
//                                                                                           )
//                                                                                               : Text("")
//                                                                                         ],
//                                                                                       ),
//                                                                                     );
//                                                                                   });
//                                                                             }
//                                                                             return CircularProgressIndicator();
//                                                                           })),
//                                                                   buildProfileButton(),
//                                                                   // ListTile(
//                                                                   //   leading: Icon(Icons.share),
//                                                                   //   title: Text("Invite Friends"),
//                                                                   //   onTap: () async {
//                                                                   //
//                                                                   //     await createdynamiclink();
//                                                                   //     final String text = url.toString();
//                                                                   //
//                                                                   //     Share.share(text);
//                                                                   //   },
//                                                                   // ),
//                                                                   SizedBox(
//                                                                     height:
//                                                                     30.0,
//                                                                   ),
//                                                                   Padding(
//                                                                     padding: const EdgeInsets
//                                                                         .symmetric(
//                                                                         horizontal:
//                                                                         32.0),
//                                                                     child:
//                                                                     Center(
//                                                                       child:
//                                                                       Column(
//                                                                         children: <
//                                                                             Widget>[
//                                                                           Text(
//                                                                             'Member Since',
//                                                                             style:
//                                                                             TextStyle(
//                                                                               fontSize: 20.0,
//                                                                               fontWeight: FontWeight.bold,
//                                                                               //color: Colors.black54,
//                                                                             ),
//                                                                           ),
//                                                                           getTime(),
//                                                                         ],
//                                                                       ),
//                                                                     ),
//                                                                   )
//                                                                 ],
//                                                               ),
//                                                             )),
//                                                       ),
//                                                     ),
//                                                     CircleAvatar(
//                                                       radius: 60,
//                                                       // backgroundColor: Colors.grey,
//                                                       backgroundImage: (imagesnapshot
//                                                           .data[
//                                                       "MediaURL"] !=
//                                                           null)
//                                                           ? NetworkImage(
//                                                           imagesnapshot
//                                                               .data[
//                                                           "MediaURL"])
//                                                           : AssetImage(
//                                                           "assets/images/blank-profile-picture-973460_640.png"),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ]),
//                                           ),
//                                         );
//                                       } else if (imagesnapshot
//                                           .connectionState ==
//                                           ConnectionState.none) {
//                                         return Container(
//                                           height: MediaQuery.of(context)
//                                               .size
//                                               .height *
//                                               0.65,
//                                           width: double.infinity,
//                                           color: Color(0xffE0E0E0),
//                                           child: Stack(children: <Widget>[
//                                             Padding(
//                                               padding:
//                                               const EdgeInsets.all(16.0),
//                                               child: Stack(
//                                                 alignment: Alignment.topCenter,
//                                                 children: <Widget>[
//                                                   Padding(
//                                                     padding: EdgeInsets.only(
//                                                       top: circleRadius / 2.0,
//                                                     ),
//
//                                                     ///here we create space for the circle avatar to get ut of the box
//                                                     child: Container(
//                                                       height: 300.0,
//                                                       decoration: BoxDecoration(
//                                                         borderRadius:
//                                                         BorderRadius
//                                                             .circular(15.0),
//                                                         color: Colors.white,
//                                                         boxShadow: [
//                                                           BoxShadow(
//                                                             color:
//                                                             Colors.black26,
//                                                             blurRadius: 8.0,
//                                                             offset: Offset(
//                                                                 0.0, 5.0),
//                                                           ),
//                                                         ],
//                                                       ),
//                                                       width: double.infinity,
//                                                       child: Padding(
//                                                           padding:
//                                                           const EdgeInsets
//                                                               .only(
//                                                               top: 15.0,
//                                                               bottom: 15.0),
//                                                           child: Column(
//                                                             children: <Widget>[
//                                                               SizedBox(
//                                                                 height:
//                                                                 circleRadius /
//                                                                     2,
//                                                               ),
//                                                               Container(
//                                                                   padding:
//                                                                   const EdgeInsets
//                                                                       .only(
//                                                                     left: 120,
//                                                                   ),
//                                                                   // padding: const EdgeInsets.symmetric(horizontal: 50),
//                                                                   child:
//                                                                   FutureBuilder(
//                                                                       future:
//                                                                       getUserInfo(),
//                                                                       builder:
//                                                                           (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
//                                                                         if (snapshot.connectionState ==
//                                                                             ConnectionState.done) {
//                                                                           return ListView.builder(
//                                                                               physics: const NeverScrollableScrollPhysics(),
//                                                                               shrinkWrap: true,
//                                                                               itemCount: 1,
//                                                                               itemBuilder: (BuildContext context, int index) {
//                                                                                 return Text(
//                                                                                   snapshot.data["username"],
//                                                                                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 34.0),
//                                                                                 );
//                                                                               });
//                                                                         }
//                                                                         return CircularProgressIndicator();
//                                                                       })),
//                                                               buildProfileButton(),
//                                                               buildProfileButton(),
//                                                               SizedBox(
//                                                                 height: 30.0,
//                                                               ),
//                                                               Padding(
//                                                                 padding: const EdgeInsets
//                                                                     .symmetric(
//                                                                     horizontal:
//                                                                     32.0),
//                                                                 child: Row(
//                                                                   mainAxisAlignment:
//                                                                   MainAxisAlignment
//                                                                       .spaceBetween,
//                                                                   children: <
//                                                                       Widget>[
//                                                                     Column(
//                                                                       children: <
//                                                                           Widget>[
//                                                                         Text(
//                                                                           "Member Since",
//                                                                           style:
//                                                                           TextStyle(
//                                                                             fontSize:
//                                                                             20.0,
//                                                                             fontWeight:
//                                                                             FontWeight.bold,
//                                                                             //color: Colors.black54,
//                                                                           ),
//                                                                         ),
//                                                                         getTime()
//                                                                       ],
//                                                                     ),
//                                                                   ],
//                                                                 ),
//                                                               )
//                                                             ],
//                                                           )),
//                                                     ),
//                                                   ),
//
//                                                   ///Image Avatar
//                                                   Container(
//                                                     width: circleRadius,
//                                                     height: circleRadius,
//                                                     decoration: BoxDecoration(
//                                                       shape: BoxShape.circle,
//                                                       color: Colors.white,
//                                                       boxShadow: [
//                                                         BoxShadow(
//                                                           color: Colors.black26,
//                                                           blurRadius: 8.0,
//                                                           offset:
//                                                           Offset(0.0, 5.0),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     child: Padding(
//                                                       padding:
//                                                       EdgeInsets.all(4.0),
//                                                       child: Center(
//                                                         child: Container(
//                                                           child: Icon(
//                                                               Icons.person),
//
//                                                           /// replace your image with the Icon
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                           ]),
//                                         );
//                                       }
//                                       return CircularProgressIndicator();
//                                     }
//
//                                   // child: CircleAvatar(
//                                   //   radius: 40,
//                                   //   // backgroundColor: Colors.grey,
//                                   //   backgroundImage: NetworkImage(
//                                   //       "https://images.immediate.co.uk/production/volatile/sites/3/2020/09/the-batman-robert-pattinson-1-ac6949e.jpg?quality=90&resize=620,413"),
//                                   // ),
//                                 ),
//                               ],
//                             ),
//
//                             SizedBox(
//                               height: 15,
//                             ),
//                             Divider(
//                               color: Colors.blueGrey,
//                             ),
//                             SizedBox(
//                               height: 5,
//                             ),
//
//                             Container(
//                               margin: EdgeInsets.only(left: 30, right: 30),
//                               child: Row(
//                                 mainAxisAlignment:
//                                 MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   GestureDetector(
//                                     onTap: () {
//                                       setPostOrientation("hiring");
//                                     },
//                                     child: Text(
//                                       "Hiring",
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         //change color based on selected field
//                                         color: PostOrientation == "hiring"
//                                             ? Colors.blue
//                                             : Colors.grey,
//                                       ),
//                                     ),
//                                   ),
//                                   GestureDetector(
//                                       onTap: () {
//                                         setPostOrientation("skills");
//                                       },
//                                       child: Text(
//                                         "Skills",
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           //change color based on selected field
//                                           color: PostOrientation == "skills"
//                                               ? Colors.blue
//                                               : Colors.grey,
//                                         ),
//                                       )),
//                                   GestureDetector(
//                                       onTap: () {
//                                         setPostOrientation("requests");
//                                       },
//                                       child: Text(
//                                         "Assistance",
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           //change color based on selected field
//                                           color: PostOrientation == "requests"
//                                               ? Colors.blue
//                                               : Colors.grey,
//                                         ),
//                                       )),
//                                 ],
//                               ),
//                             ),
//                             SizedBox(
//                               height: 5,
//                             ),
//                             Divider(
//                               color: Colors.blueGrey,
//                             ),
//
//                             buildprofileposts(),
//
//                             // _HiringPosts(),
//                             SizedBox(
//                               height: 40,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }