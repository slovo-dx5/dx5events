import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants.dart';

class NotificationIconButton extends StatefulWidget {
  @override
  State<NotificationIconButton> createState() => _NotificationIconButtonState();
}


class _NotificationIconButtonState extends State<NotificationIconButton> {
String? userID;


  getUSerID(){
    getIntPref( kUserID).then((value) {
      setState(() {
        userID=value.toString();
      });

    });
  }

  @override
  void initState() {
    // TODO: implement initState
    getUSerID();
  }
  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> stream1 = FirebaseFirestore.instance.collection('collection1').snapshots();
    Stream<QuerySnapshot> stream2 = FirebaseFirestore.instance.collection('collection2').snapshots();
    //var combinedStream = StreamZip([stream1, stream2]);
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('notifications').doc(userID).collection(userID!).snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Icon(Icons.error);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
         // return const CircularProgressIndicator();
          return IconButton(
            icon: const Icon(Icons.notifications,size: 35,),
            onPressed: () {
              // Handle notification icon press
            },
          );
        }

        int docsCount = snapshot.data?.docs.length ?? 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications,size: 35,),
              onPressed: () {
                // Handle notification icon press
              },
            ),
            if (docsCount > 0)
              Positioned(
                right: 1,
                top: 1,

                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    '$docsCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
