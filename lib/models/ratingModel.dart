// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class RatingModel {
//   String currentUserID;
//   int starsCount;
//   String comment;
//   String latestMessage;
//   String myId;
//   String senderID;
//   String chatId;
//
//
//   RatingModel({
//     required this.otherpersonuid,
//     required this.addedOn,
//     required this.sentto,
//     required this.sentFrom,
//     required this.latestMessage,
//     required this.myId,
//     required this.senderID,
//     required this.chatId,
//
//   });
//
//   Map<String, dynamic> toMap(RatingModel receiverContact) {
//     return {
//       'contact_id': otherpersonuid,
//       'added_on': addedOn,
//       'Sent_To': sentto,
//       'latest_message': latestMessage,
//       'Sent_From': sentFrom,
//       'my_id': myId,
//       'sender_id': senderID,
//       'chatID': chatId,
//
//     };
//   }
//
//   factory RatingModel.fromMap(Map<String, dynamic> mapData) {
//     return RatingModel(
//       otherpersonuid: mapData['contact_id'],
//       addedOn: mapData['added_on'],
//       sentto: mapData['Sent_To'],
//       latestMessage: mapData['latest_message'],
//       sentFrom: mapData['Sent_From'],
//       myId: mapData['my_id'],
//       senderID: mapData['sender_id'],
//       chatId: mapData['chatID'],
//
//     );
//   }
// }
