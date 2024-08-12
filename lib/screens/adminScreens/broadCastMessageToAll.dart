import "package:dx5veevents/constants.dart";
import "package:flutter/material.dart";

import "../../backendOps/sendBroadcast.dart";
import "../../dioServices/dioPostService.dart";
import "../../notifications/pushNotifications.dart";
class BroadCastMessageToAll extends StatefulWidget {
  const BroadCastMessageToAll({super.key});

  @override
  State<BroadCastMessageToAll> createState() => _BroadCastMessageToAllState();
}

class _BroadCastMessageToAllState extends State<BroadCastMessageToAll> {
  TextEditingController messageBodyController=TextEditingController();
  TextEditingController titleController=TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Widget _buildMessageBody(){
    return
      TextFormField(
        textCapitalization: TextCapitalization.sentences,
        controller: messageBodyController,
        maxLines: null, //IMPORTANT: Facilitates flow of text downwards while typing
        decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Message",
            contentPadding: EdgeInsets.symmetric(vertical: 70.0, horizontal: 10.0),
            hintText: "Your message"
        ),
        validator: ( value){
          if(value!.isEmpty){
            return "Enter a message";
          }if(value.trim().length <15){
            return "Message must be at least 10 characters";
          }
          return null;
        },

      );
  }
  Widget buildTitle(){
    return TextFormField(
      style: const TextStyle(
          color: kLighterGreenAccent
      ),
      controller: titleController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(

        labelStyle: TextStyle(fontSize: 12,color:kLighterGreenAccent ),
        labelText: 'Title',
        prefixIcon: Icon(Icons.email,size: 20,color: kLighterGreenAccent,),
        //contentPadding: EdgeInsets.all(20),
      ),

      // The validator receives the text that the user has entered.
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Title is required';
        }
        return null;
      },
    );
  }


  @override
  void dispose() {
    titleController.dispose();
    messageBodyController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(body: Form(key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
          buildTitle(),
            verticalSpace(height: 20),
            _buildMessageBody(),
            verticalSpace(height: 20),
            primaryButton2(context: context, onPressedFunction: ()async{
              if(_formKey.currentState!.validate()){
                await NotificationSetup().getIOSPermission();
                try {
                  final token = await getAccessToken();
                  await DioPostService().sendBroadcast(body: {
                    "message": {
                      "topic": "dx5veBroadcast",
                      "notification": {
                        "title": titleController.text,
                        "body": messageBodyController.text
                      },

                    }
                  }
                    , accessToken: token, );
                  print('broadcast success');
                } catch (e) {
                  print('access token errorError: $e');
                }

              }
            }, buttonText: "Send", backgroundColor: kIconBlue)

          ],),
        ),
      ) ,),
    );
  }
}
