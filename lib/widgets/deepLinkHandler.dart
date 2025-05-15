// // First, add these dependencies to your pubspec.yaml:
// // uni_links: ^0.5.1
//
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:uni_links5/uni_links.dart';
// class DeepLinkHandler extends StatefulWidget {
//   final Widget child;
//
//   const DeepLinkHandler({Key? key, required this.child}) : super(key: key);
//
//   @override
//   _DeepLinkHandlerState createState() => _DeepLinkHandlerState();
// }
//
// class _DeepLinkHandlerState extends State<DeepLinkHandler> {
//   StreamSubscription? _linkSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     initUniLinks();
//   }
//
//   Future<void> initUniLinks() async {
//     // Handle app start by deep link
//     try {
//       final initialLink = await getInitialLink();
//       if (initialLink != null) {
//         _handleDeepLink(initialLink);
//       }
//     } on PlatformException {
//       // Handle exception
//     }
//
//     // Handle links when app is already running
//     _linkSubscription = linkStream.listen((String? link) {
//       if (link != null) {
//         _handleDeepLink(link);
//       }
//     }, onError: (err) {
//       // Handle exception
//     });
//   }
//
//   void _handleDeepLink(String link) {
//     // Parse the URI
//     final uri = Uri.parse(link);
//
//     // Check if it's a meetings link
//     if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'meetings') {
//       // Extract meeting ID from query parameters
//       final meetingId = uri.queryParameters['id'];
//       if (meetingId != null) {
//         // Navigate to the meetings page with the ID
//         Navigator.of(context).pushNamed('/meetings', arguments: meetingId);
//       } else {
//         // If no ID is provided, just navigate to the meetings page
//         Navigator.of(context).pushNamed('/meetings');
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _linkSubscription?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return widget.child;
//   }
// }
//
