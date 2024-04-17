import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../providers.dart';
class ProfileInitials extends StatefulWidget {
  const ProfileInitials({super.key});

  @override
  State<ProfileInitials> createState() => _ProfileInitialsState();
}

class _ProfileInitialsState extends State<ProfileInitials> {

  Random random = Random();
  final int randomIndex = Random().nextInt(predefinedColors.length);
  late Color randomBackgroundColor;

  String? firstName;
  String? lastName;

  @override
  void initState() {
    setState(() {
      randomBackgroundColor= predefinedColors[randomIndex];
    });
    getNames();
    super.initState();

  }

  getNames()async{
     getStringPref(kFirstName).then((value) {
      setState(() {
        firstName=value;
      });
    });
     getStringPref(kLastName).then((value) {
       setState(() {
         lastName=value;
       });
     });

  }
  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    return  CircleAvatar(backgroundColor:randomBackgroundColor,radius: 80,child: Center(child: Text("${profileProvider.firstName![0].toUpperCase()}${profileProvider.lastName![0].toUpperCase()}", style: const TextStyle(color: Colors.white,fontSize: 60),)),);

  }
}


class ProfilePicWidget extends StatefulWidget {
  const ProfilePicWidget({super.key});

  @override
  State<ProfilePicWidget> createState() => _ProfilePicWidgetState();
}

class _ProfilePicWidgetState extends State<ProfilePicWidget> {
  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    return
      // CircleAvatar(radius: 80,backgroundColor: kCIOPink.withOpacity(0.5),
      // backgroundImage: NetworkImage("https://subscriptions.cioafrica.co/assets/${profileProvider.profileId}"),
      // );

    // CachedNetworkImage(
    //   imageUrl:"https://subscriptions.cioafrica.co/assets/${profileProvider.profileId}",
    //   progressIndicatorBuilder: (context, url, downloadProgress) =>
    //       CircularProgressIndicator(value: downloadProgress.progress),
    //   errorWidget: (context, url, error) => const ProfileInitials(),
    // );
      CachedNetworkImage(
        imageUrl: "https://subscriptions.cioafrica.co/assets/${profileProvider.profileId}",
        // placeholder: (context, url) => CircularProgressIndicator(), // Optional
        // errorWidget: (context, url, error) =>  ProfileInitials(),
        progressIndicatorBuilder: (context, url, downloadProgress) =>
           CircularProgressIndicator(value: downloadProgress.progress),// Optional
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 80,
          backgroundImage: imageProvider,
        ),
      );



  }
}

class AttendeeProfileInitials extends StatefulWidget {
  String firstName;
  String lastName;
   AttendeeProfileInitials({super.key, required this.firstName,required this.lastName });

  @override
  State<AttendeeProfileInitials> createState() => _AttendeeProfileInitialsState();
}

class _AttendeeProfileInitialsState extends State<AttendeeProfileInitials> {

  Random random = Random();
  final int randomIndex = Random().nextInt(predefinedColors.length);
  late Color randomBackgroundColor;



  @override
  void initState() {
    setState(() {
      randomBackgroundColor= predefinedColors[randomIndex];
    });

    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return  CircleAvatar(backgroundColor:randomBackgroundColor,radius: 30,child: Center(child: Text("${widget.firstName[0].toUpperCase()}${widget.lastName[0].toUpperCase()}", style: const TextStyle(color: Colors.white,fontSize: 25),)),);

  }
}

class IndividualAttendeeProfileInitials extends StatefulWidget {
  String firstName;
  String lastName;
  IndividualAttendeeProfileInitials({required this.firstName,required this.lastName });

  @override
  State<IndividualAttendeeProfileInitials> createState() => _IndividualAttendeeProfileInitialsState();
}

class _IndividualAttendeeProfileInitialsState extends State<IndividualAttendeeProfileInitials> {

  Random random = Random();
  final int randomIndex = Random().nextInt(predefinedColors.length);
  late Color randomBackgroundColor;



  @override
  void initState() {
    setState(() {
      randomBackgroundColor= predefinedColors[randomIndex];
    });

    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return  CircleAvatar(
      radius: 70,
      backgroundColor:randomBackgroundColor,child: Center(child: Text("${widget.firstName[0].toUpperCase()}${widget.lastName[0].toUpperCase()}", style: const TextStyle(color: Colors.white,fontSize: 80),)),);

  }
}



class AttendeeProfilePicWidget extends StatefulWidget {
  String profileID;
  AttendeeProfilePicWidget({required this.profileID,super.key});

  @override
  State<AttendeeProfilePicWidget> createState() => _AttendeeProfilePicWidgetState();
}

class _AttendeeProfilePicWidgetState extends State<AttendeeProfilePicWidget> {
  @override
  Widget build(BuildContext context) {

    return
      // CircleAvatar(radius: 80,backgroundColor: kCIOPink.withOpacity(0.5),
      // backgroundImage: NetworkImage("https://subscriptions.cioafrica.co/assets/${profileProvider.profileId}"),
      // );

      // CachedNetworkImage(
      //   imageUrl:"https://subscriptions.cioafrica.co/assets/${profileProvider.profileId}",
      //   progressIndicatorBuilder: (context, url, downloadProgress) =>
      //       CircularProgressIndicator(value: downloadProgress.progress),
      //   errorWidget: (context, url, error) => const ProfileInitials(),
      // );
      CachedNetworkImage(
        imageUrl: "https://subscriptions.cioafrica.co/assets/${widget.profileID}",
        // placeholder: (context, url) => CircularProgressIndicator(), // Optional
        // errorWidget: (context, url, error) =>  ProfileInitials(),
        progressIndicatorBuilder: (context, url, downloadProgress) =>
            CircularProgressIndicator(value: downloadProgress.progress),// Optional
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 30,
          backgroundImage: imageProvider,
        ),
      );



  }
}
class IndividualAttendeeProfilePicWidget extends StatefulWidget {
  String profileID;
  IndividualAttendeeProfilePicWidget({required this.profileID,super.key});

  @override
  State<IndividualAttendeeProfilePicWidget> createState() => _IndividualAttendeeProfilePicWidgetState();
}

class _IndividualAttendeeProfilePicWidgetState extends State<IndividualAttendeeProfilePicWidget> {
  @override
  Widget build(BuildContext context) {

    return
      // CircleAvatar(radius: 80,backgroundColor: kCIOPink.withOpacity(0.5),
      // backgroundImage: NetworkImage("https://subscriptions.cioafrica.co/assets/${profileProvider.profileId}"),
      // );

      // CachedNetworkImage(
      //   imageUrl:"https://subscriptions.cioafrica.co/assets/${profileProvider.profileId}",
      //   progressIndicatorBuilder: (context, url, downloadProgress) =>
      //       CircularProgressIndicator(value: downloadProgress.progress),
      //   errorWidget: (context, url, error) => const ProfileInitials(),
      // );
      CachedNetworkImage(
        imageUrl: "https://subscriptions.cioafrica.co/assets/${widget.profileID}",
        // placeholder: (context, url) => CircularProgressIndicator(), // Optional
        // errorWidget: (context, url, error) =>  ProfileInitials(),
        progressIndicatorBuilder: (context, url, downloadProgress) =>
            CircularProgressIndicator(value: downloadProgress.progress),// Optional
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 120,
          backgroundImage: imageProvider,
        ),
      );



  }
}
