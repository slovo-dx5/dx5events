import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import '../../constants.dart';
import '../../dioServices/dioPostService.dart';
import '../../helpers/helper_functions.dart';
import '../../models/contact_model.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';






// ignore: must_be_immutable
class CioChatScreen extends StatefulWidget {
  int currentUserID;
  int chattingWithID;
  String chattingWithName;
  String currentUserName;



  CioChatScreen({
    required this.chattingWithName, required this.chattingWithID,required this.currentUserID,required this.currentUserName
  });

  @override
  _CioChatScreenState createState() => _CioChatScreenState();
}

class _CioChatScreenState extends State<CioChatScreen> {
  //String futureHiringPostOwnerID;
  // Future<DocumentSnapshot> getOwnerInfo() async {
  //   return await FirebaseFirestore.instance
  //       .collection("users")
  //       .doc(widget.futureHiringPostOwnerID)
  //       .get();
  // }


  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listscrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  String? currentuid;
  String? id;
  String? newreceiverId;
  String? chatId;
  String? mynotificationId;
  String? othernotificationId;
  String? sentToname;
  String? sentFromname;
  String? receiverToken;
  var listMessage;
  var imageFile;
  String ?ImageUrl;
  bool? isLoading=false;
  final picker = ImagePicker();
  String? lastMessage;
  String? sentFromID;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    focusNode.addListener(onFocusChange);
    getReceiverToken();


    chatId = "";
    // getmessages().then((results) {
    //   setState(() {
    //     usermessages = results;
    //   });
    // });

    readLocal();


  }

  Future getReceiverInfo() async {
    //String name;
    // var firebaseUser = await FirebaseAuth.instance.currentUser();


    setState(() {
      sentToname = widget.chattingWithName;

    });
  }
  Future getSenderInfo() async {
    //String name;
    // var firebaseUser = await FirebaseAuth.instance.currentUser();
    var document = await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .get();
    setState(() {
      sentFromname = widget.currentUserName;
      sentFromID=widget.currentUserID.toString();
    });


  }

  getReceiverToken()async {
 try{
   DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
     .collection("users").doc(widget.chattingWithID.toString()).get();
       //.collection("users").doc("158").get();

   if (documentSnapshot.exists) {
     // Replace 'field_name' with the name of the field you want to fetch
     setState(() {
       receiverToken=documentSnapshot.get('messaging_token').toString();
       print("receiver token is $receiverToken");
     });
     return documentSnapshot.get('messaging_token').toString();
   } else {
     return 'Document does not exist';
   }
 }catch(e){
   print("Coul not get user id");
 }
  }


  DocumentReference getContactsDocument({required String of, required String forContact})=>
      FirebaseFirestore.instance
          .collection("users")
          .doc(of)
          .collection("contacts")
          .doc(forContact);

  Future<void>AddTosendersContacts(String senderId,String otherpersonId,currentTime)async{
    DocumentSnapshot sendersnapshot=await getContactsDocument(of: senderId,forContact: otherpersonId).get();

    if(!sendersnapshot.exists){
      await getReceiverInfo();
      await getSenderInfo();
     // await getLastMessage();

      //if senders doc does not exist
      Contact receiverContact=Contact(
          otherpersonuid:otherpersonId,
          addedOn:currentTime,
          sentto:widget.chattingWithName,
          sentFrom:widget.currentUserName,
          latestMessage:textEditingController.text!,
          myId: id!,
          senderID: otherpersonId,
          chatId: chatId!,




      );
      var receiverMap= receiverContact.toMap(receiverContact);
      await getContactsDocument(of: senderId,forContact: otherpersonId).set(receiverMap);

    }
  }
  // ignore: non_constant_identifier_names
  Future<void>AddToOtherPersonContacts(String senderId,String otherpersonId,currentTime)async{
    DocumentSnapshot otherpersonsnapshot=await getContactsDocument(of: otherpersonId,forContact:senderId ).get();

    if(!otherpersonsnapshot.exists){
      await getReceiverInfo();
      await getSenderInfo();
     // await getLastMessage();
      await readLocal();

      //if senders doc does not exist
      Contact senderContact=Contact(
        otherpersonuid:otherpersonId,
        addedOn:currentTime,
        sentto:sentToname!,
        latestMessage:textEditingController.text!,
        sentFrom:sentFromname!,
        myId:otherpersonId,
        senderID: senderId,
        chatId: chatId!,



      );
      var senderMap= senderContact.toMap(senderContact);
      await getContactsDocument(of: otherpersonId,forContact: senderId).set(senderMap);

    }
  }
  addtocontacts({required String senderId, required String otherpersonId})async{
    Timestamp currentTime=Timestamp.now();
    await AddTosendersContacts(senderId, otherpersonId, currentTime);
    await AddToOtherPersonContacts(senderId, otherpersonId, currentTime);
    // FirebaseFirestore.instance
    //     .collection("users")
    //     .doc(id)
    //     .collection("contacts").doc(otherpersonId);

  }

  onSendMessage(String messagecontent, int type) async{



    if (messagecontent != "") {
      textEditingController.clear();
      var docref = FirebaseFirestore.instance
          .collection("messages")
          .doc(chatId)
          .collection(chatId!)
          .doc(DateTime.now().millisecondsSinceEpoch.toString());

     await addtocontacts( senderId:id!, otherpersonId: newreceiverId!);

   await   FirebaseFirestore.instance.runTransaction((transaction) async{
        transaction.set(docref,{
          'idFrom': id,
          'idTo': newreceiverId,

          // 'timestamp': DateTime.now().millisecondsSinceEpoch,
          'timestamp': FieldValue.serverTimestamp(),
          'content': messagecontent,
          'type':type,
          'isread':false,
          "sentTo":sentToname,
          "sentFrom":sentFromname,
        },);
      });



      await addtonotifications();

      await DioPostService().sendNotification({"to": receiverToken,
        "notification":{
          "title": sentFromname,
          "body": messagecontent
        }
      });
      listscrollController.animateTo(0.0,
          duration: Duration(microseconds: 300), curve: Curves.easeOut);
      await getSenderInfo();

    } else {
      Fluttertoast.showToast(msg: "Cannot Send an empty message");
    }

  }
  addtonotifications(){
    bool isPostOwner = currentuid == newreceiverId;
    if (isPostOwner) {
      notificationsRef.doc(othernotificationId)
          .collection(othernotificationId!).add(
          {"chattid":chatId,
            "isread":false,


          });}
    else if(!isPostOwner){ notificationsRef.doc(newreceiverId)
        .collection(newreceiverId!).add(
        {"chattid":chatId,
          "isread":false,


        });}


  }


  onFocusChange(){}

  getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    imageFile=File(pickedFile!.path);
    if (imageFile != null) {
      //return Text("Loading");
      isLoading = true;
    }
    uploadImageFile();
  }

  Future uploadImageFile() async {
    String filename = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageReference =
    FirebaseStorage.instance.ref().child("chat images").child(filename);
    UploadTask uploadTask = storageReference.putFile(imageFile);

    ImageUrl = await (await uploadTask).ref.getDownloadURL();
    setState(() {
      isLoading = false;
      onSendMessage(ImageUrl!, 1);
    });
    return ImageUrl;
  }

  readLocal() async {

    currentuid=widget.currentUserID.toString();
    id=widget.currentUserID.toString();


    newreceiverId = widget.chattingWithID.toString();

    id.hashCode <= newreceiverId.hashCode
        ? chatId='$id-$newreceiverId'
        : chatId='$newreceiverId-$id';

    id.hashCode <= newreceiverId.hashCode
        ? mynotificationId=id
        : othernotificationId=id;


    // if (id.hashCode <= receiverid.hashCode) {
    //chatId = '$id-$newreceiverId';
    //  chatId = '$id-$receiverid';


    //}
    // else {
    //   chatId = '$newreceiverId-$id';
    // }

    setState(() {});
  }
  bool IsLastMsgLeft(int index) {
    if ((index > 0 &&
        listMessage != null
        &&
        listMessage[index - 1]["idFrom"] != id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool IsLastMsgRight(int index) {
    if ((index > 0 &&
        listMessage != null &&
        listMessage[index - 1]["idFrom"] == id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }
  Widget createItem(int index, DocumentSnapshot document) {
    DateTime myDateTime = (document['timestamp']).toDate();
    var messageTime=DateFormat.MMMd().add_jm().format(myDateTime);
    //current users messages right side
    if (document["idFrom"] == id) {
      return Padding(
        padding: const EdgeInsets.only(left:40.0),
        child: Row(

          mainAxisAlignment: MainAxisAlignment.end,

          children: [
            //text message
            document["type"] == 0
                ? Flexible(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left:2.0,bottom: 8,top: 8),
                    child: Material(
                      borderRadius: BorderRadius.only(topLeft:Radius.circular(15.0),bottomLeft: Radius.circular(15.0),bottomRight: Radius.circular(15.0)),
                      elevation: 5.0 ,
                      color:kRightBubble,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7.5,horizontal: 7.5),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Row(mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Column(mainAxisAlignment: MainAxisAlignment.start,mainAxisSize: MainAxisSize.min,crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      document["content"],
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5.0,),
                              Padding(
                                padding: const EdgeInsets.only(right:0.0,top: 20.0,left: 15.0,bottom: 1),
                                child: Text(messageTime,style: TextStyle(color: Colors.black54,fontSize: 9.0),),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
                :
            //image message
            Container(
              margin: EdgeInsets.only(
                  bottom: IsLastMsgRight(index) ? 20.0 : 10.0, right: 10.0),
              child: TextButton(
                child: Material(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(8.0),
                  ),
                  child: CachedNetworkImage(
                    placeholder: (context, url) => Container(
                      width: 200.0,
                      height: 200.0,
                      padding: const EdgeInsets.all(70.0),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                      ),
                      child: const CircularProgressIndicator(
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.pink),
                      ),
                    ),
                    errorWidget: (context, url, error) => Material(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Image.asset(
                        "assets/images/imagenotavailable.jpg",
                        width: 200.0,
                        height: 200.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                    imageUrl: document["content"],
                    width: 200.0,
                    height: 200.0,
                    fit: BoxFit.cover,
                  ),
                ),
                onPressed: () {


                },
              ),
            ),
          ],
        ),
      );
    }
    //messages being received left side
    else {
      return
        Padding(
          padding: const EdgeInsets.only(right:40.0),
          child: Row(
            children: [
              IsLastMsgLeft(index)?
              const Material(

                borderRadius: BorderRadius.all(Radius.circular(18.0),

                ),
                clipBehavior: Clip.hardEdge,
              ):
              Container(padding: const EdgeInsets.only(left:4.0,right: 2.0),),
              //display messages
              document["type"] == 0
                  ? Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.start,crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left:2.0,bottom: 8.0,top:8.0),
                      child: Material(
                        borderRadius: BorderRadius.only(topRight:Radius.circular(15.0),bottomLeft: Radius.circular(15.0),bottomRight: Radius.circular(15.0)),
                        elevation: 5.0 ,
                        color: kLightGrayishOrange,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 20.0),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      document["content"],
                                      style: const TextStyle(fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5.0,),

                              Padding(
                                padding: const EdgeInsets.only(right:0.0,top: 20.0,left: 15.0,bottom: 1),
                                child: Text(messageTime
                                  // document["timestamp"].toDate().toString()

                                  ,style: const TextStyle(color: Colors.black54,fontSize: 9.0),),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  :
              //image message
              Container(
                margin: const EdgeInsets.only(
                    left: 10.0),
                child: TextButton(
                  child: Material(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(8.0),
                    ),
                    child: CachedNetworkImage(
                      placeholder: (context, url) => Container(
                        width: 200.0,
                        height: 200.0,
                        padding: const EdgeInsets.all(70.0),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                        ),
                        child: const CircularProgressIndicator(
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.pink),
                        ),
                      ),
                      errorWidget: (context, url, error) => Material(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Image.asset(
                          "assets/images/imagenotavailable.jpg",
                          width: 200.0,
                          height: 200.0,
                          fit: BoxFit.cover,
                        ),
                      ),
                      imageUrl: document["content"],
                      width: 200.0,
                      height: 200.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                  onPressed: () {

                  },
                ),
              ),
              IsLastMsgLeft(index)
                  ? Container(

                margin: const EdgeInsets.only(left: 50.0,top: 50.0,bottom: 5.0),
              )
                  : Container()
            ],
          ),
        );

    }
  }
  createMessageList() {

    return Flexible(
      child: chatId == ""
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlue),
        ),
      )
          : StreamBuilder(


          stream: FirebaseFirestore.instance
              .collection('messages')
              .doc(chatId)
              .collection(chatId!)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          //addtocontacts(){}

          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                //child: Text("getting messages"),
                child: CircularProgressIndicator(),
              );
            } else {
              listMessage = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(10.0),
                itemBuilder: (context,index)=>createItem(index, snapshot.data!.docs[index]),
                itemCount: snapshot.data!.docs.length,
                reverse: true,
                controller: listscrollController,

              );
            }
          }
      ),
    );
  }

  createInput() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0,right: 12,),
        child: Row(
          children: [
            //pick image from gallery
            // IconButton(
            //     icon: const Icon(Icons.image),
            //     color: Colors.lightBlueAccent,
            //     onPressed: () => getImage()
            //   //onPressed: () => getMessages()
            //
            // ),

            //text field
            Flexible(
              child: TextField(
                style: const TextStyle(fontSize: 15.0),
                maxLines: null,
                controller: textEditingController,
                decoration: const InputDecoration.collapsed(
                  hintText: "Text Message",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                focusNode: focusNode,
              ),
            ),
            //send message icon button
            IconButton(
              icon: Icon(Icons.send),
              // onPressed: () => onSendMessage(textEditingController.text, 0),
              onPressed: (){ onSendMessage(textEditingController.text, 0);
              },
            )
          ],
        ),
      ),
    );
  }





  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          centerTitle: false,

          title: Text(
            widget.chattingWithName,style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          ),
        ),
        body: Stack(
    children: [
    Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch ,
      children: [
        createMessageList(),
        //input controllers
        createInput()
      ],
    )
    ],
    )

    );
  }
}








