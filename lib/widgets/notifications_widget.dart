import 'package:dx5veevents/screens/dx5veScreens/notificationsScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../constants.dart';

class NotificationIconButton extends StatefulWidget {
  const NotificationIconButton({super.key});

  @override
  State<NotificationIconButton> createState() => _NotificationIconButtonState();
}

class _NotificationIconButtonState extends State<NotificationIconButton> {
  String? userID;

  getUSerID() {
    getIntPref(kUserID).then((value) {
      if (mounted) {
        setState(() {
          userID = value.toString();
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getUSerID();
  }

  void _navigateToNotifications(BuildContext context) {
    PersistentNavBarNavigator.pushNewScreen(
      context,
      screen: const NotificationsScreen(),
      withNavBar: false,
      pageTransitionAnimation: PageTransitionAnimation.slideRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userID == null) {
      return IconButton(
        icon: const Icon(Icons.notifications, size: 35),
        onPressed: () => _navigateToNotifications(context),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .collection('meetings')
          .where('isAccepted', isEqualTo: false)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return IconButton(
            icon: const Icon(Icons.notifications, size: 35),
            onPressed: () => _navigateToNotifications(context),
          );
        }

        // Count only incoming, non-expired meeting requests
        final now = DateTime.now();
        final incomingCount = snapshot.data!.docs.where((doc) {
          final requestedById = doc['requested_by_id'] as String?;
          final dateRequested = (doc['date_requested'] as Timestamp).toDate();
          final isExpired =
              dateRequested.add(const Duration(hours: 24)).isBefore(now);
          return requestedById != userID && !isExpired;
        }).length;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, size: 35),
              onPressed: () => _navigateToNotifications(context),
            ),
            if (incomingCount > 0)
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
                    '$incomingCount',
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
