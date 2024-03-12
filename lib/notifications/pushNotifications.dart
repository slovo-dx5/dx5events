import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
class NotificationSetup{

  final FirebaseMessaging _firebaseMessaging=FirebaseMessaging.instance;

  getMessagingToken()async{
    await _firebaseMessaging.requestPermission();
    await _firebaseMessaging.getToken().then((tkn) {
      if(tkn!=null){
          print("token is $tkn");
      }
    });
  }

  // initializeNotifications()async{
  //   AwesomeNotifications().initialize('resource://drawable/res_launcher_icon', [
  //     NotificationChannel(channelKey: 'mychanel', channelName: "Chat Notifications",
  //         channelDescription: "Chat Notifications",importance: NotificationImportance.Max,
  //       vibrationPattern: highVibrationPattern,
  //       channelShowBadge: true,
  //
  //     )
  //   ]);
  //   AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
  //     if (!isAllowed){
  //       AwesomeNotifications().requestPermissionToSendNotifications();
  //     }
  //   });
  // }

  getIOSPermission(){
    if(Platform.isIOS){    _firebaseMessaging.requestPermission(alert: true,badge: true,sound: true,provisional: false);
    }
  }

  @pragma("vm:entry-point")
  Future<dynamic>  myBackgroundMessageHandler(RemoteMessage message)async{
    //await Firebase.initializeApp();
    print("Handling a background message");
  }
  //
  // createOrderNotification({required String title, required String body})async{
  //   await AwesomeNotifications().createNotification(content: NotificationContent(id: 0, channelKey: "mychanel",
  //   title: title,
  //     body: body,
  //
  //   ));
  //
  // }
  //
  // eventListenerCallback(){
  //   AwesomeNotifications().setListeners(onActionReceivedMethod: NotificationController.onActionReceivedMethod);
  //
  // }
  configurePushNotifications()async{
    //await initializeNotifications();
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true,badge: true,sound: true);

    if (Platform.isIOS)getIOSPermission();
    FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message)async {
      if(message.notification !=null){
        //createOrderNotification(title:message.notification!.title!, body: message.notification!.body!);
      }
    });
  }
}


// class NotificationController{
//   @pragma("vm:entry-point")
//   static Future<void> onActionReceivedMethod(ReceivedNotification receivedNotification)async {
//
//   }
// }