import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';


import '../constants.dart';
import '../providers.dart';
import '../screens/dx5ve_social/social_feed.dart';
import '../screens/dx5veScreens/eventSpeakersScreen.dart';
import '../screens/dx5veScreens/dx5ve_partners_screen.dart';
import '../screens/dx5veScreens/event_sessions_screen.dart';
import '../screens/dx5veScreens/dx5ve_sponsors_screen.dart';
import '../screens/dx5veScreens/dx5veAttendeesScreen.dart';
import '../screens/dx5veScreens/eventAgendaScreen.dart';
import '../screens/contact_scanning/getContact.dart';
import '../screens/feedback_page.dart';
import '../screens/rewardsPage.dart';
import '../test.dart';
import 'cio_widgets.dart';
import 'clickableBanner.dart';

class HomePageWidget extends StatefulWidget {
  String coverImagepath;
  String eventName;
  String shortEventDescription;
  String eventDayOfWeek;
  String eventDate;
  String eventLocation;
  String eventID;
  int eventDay;
  int eventMonth;
  int eventYear;
  bool isCustomerEvent;

  HomePageWidget({
    super.key,
    required this.isCustomerEvent,
    required this.coverImagepath,
    required this.eventName,
    required this.eventDate,
    required this.eventDayOfWeek,
    required this.eventLocation,
    required this.eventID,
    required this.shortEventDescription,
    required this.eventDay,
    required this.eventMonth,
    required this.eventYear
  });

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return UpgradeAlert(
      upgrader: Upgrader(
          durationUntilAlertAgain: const Duration(hours: 1)
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Hero Section with improved overlay for better text readability
              Stack(
                children: [
                  // Cover Image
                  Image.asset(
                    "assets/images/themes/smart-landscape.jpg",
                    width: screenWidth,
                    height: screenHeight * 0.3, // Made taller for more visual impact
                    fit: BoxFit.fill,
                  ),
                  // Gradient overlay for better text visibility
                  Container(
                    width: screenWidth,
                    height: screenHeight * 0.3,
                    // decoration: BoxDecoration(
                    //   gradient: LinearGradient(
                    //     begin: Alignment.topCenter,
                    //     end: Alignment.bottomCenter,
                    //     colors: [
                    //       Colors.black.withOpacity(0.1),
                    //       Colors.black.withOpacity(0.7),
                    //     ],
                    //   ),
                    // ),
                  ),
                  // Event title overlay
                  // Positioned(
                  //   bottom: 20,
                  //   left: 20,
                  //   right: 20,
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Text(
                  //         widget.eventName.toUpperCase(),
                  //         style: const TextStyle(
                  //           fontSize: 26,
                  //           fontWeight: FontWeight.bold,
                  //           color: Colors.white,
                  //           letterSpacing: 0.5,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 5),
                  //       Row(
                  //         children: [
                  //           const Icon(Icons.calendar_month, color: Colors.white, size: 16),
                  //           const SizedBox(width: 5),
                  //           Text(
                  //             widget.eventDate,
                  //             style: const TextStyle(
                  //               fontSize: 14,
                  //               color: Colors.white,
                  //               fontWeight: FontWeight.w500,
                  //             ),
                  //           ),
                  //           const SizedBox(width: 15),
                  //           const Icon(Icons.location_on, color: Colors.white, size: 16),
                  //           const SizedBox(width: 5),
                  //           Text(
                  //             widget.eventLocation,
                  //             style: const TextStyle(
                  //               fontSize: 14,
                  //               color: Colors.white,
                  //               fontWeight: FontWeight.w500,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),

              // Event Description Section
              Container(
                padding: const EdgeInsets.all(20),
                child: Text(
                  widget.shortEventDescription,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Divider(),

              // Main Navigation Grid - Redesigned with card approach
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildFeatureCard(
                          context,
                          'Agenda',
                          'assets/icons/agenda.png',
                          kConnectedGreen,
                          EventAgendaScreen(
                            eventID: widget.eventID,
                            eventDay: widget.eventDay,
                            eventMonth: widget.eventMonth,
                            eventYear: widget.eventYear,
                            eventLocation: widget.eventLocation,
                            eventDayOfWeek: widget.eventDayOfWeek,
                          ),
                          'agenda_page_opened',
                        ),
                        const SizedBox(width: 12),
                        _buildFeatureCard(
                          context,
                          'Networking',
                          'assets/icons/attendee.png',
                          kConnectedOrange,
                          AttendeesScreen(
                            eventID: widget.eventID,


                          ),
                          'attendees_page_opened',
                        ),
                      ],
                    ),
                    verticalSpace(height: 12),
                    Row(
                      children: [
                        _buildFeatureCard(
                          context,
                          'Social',
                          'assets/icons/social-media.png',
                          kConnectedGreen,
                          const SocialFeed(),
                          'social_page_opened',
                        ),
                        const SizedBox(width: 12),
                        _buildFeatureCard(
                          context,
                          'Contact Scanner',
                          'assets/icons/scanner.png',
                          kConnectedRed,
                          GetContact(ownerID: profileProvider.userID!),
                          'contact_scanner_page_opened',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFeatureCard(
                          context,
                          'Speakers',
                          'assets/icons/speaker.png',
                          kConnectedBlue,
                          EventSpeakersScreen(eventID: widget.eventID),
                          'speakers_page_opened',
                        ),
                        const SizedBox(width: 12),
                        _buildFeatureCard(
                          context,
                          'Sponsors',
                          'assets/icons/sponsors.png',
                          kConnectedOrange,
                          CISOSponsorsScreen(eventID: widget.eventID),
                          'sponsors_page_opened',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                   const SizedBox(width: 12),
                         _buildFeatureCard(
                          context,
                          'Feedback',
                          'assets/icons/feedback.png',
                          kConnectedOrange,
                           FeedbackPage(
                            eventID: widget.eventID,
                             attendeeID: profileProvider.profileId!,
                             attendeeName: "${profileProvider.firstName} ${profileProvider.lastName}",
                         
                          ),
                          'feedback_page_opened',
                                                 ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced feature card widget
  Widget _buildFeatureCard(
      BuildContext context,
      String title,
      String iconPath,
      Color color,
      Widget screen,
      String analyticsAction,
      ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Add your analytics tracking here if needed
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
Future<void> _launchURL(BuildContext context) async {
  String mapUrl="https://www.residencetechnologies.com/home/resident_map/";
  final Uri uri = Uri.parse(mapUrl);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    // Show error if URL can't be launched
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open site'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _showConfirmationDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // User must tap a button to close the dialog
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.open_in_new, color: Colors.blue),
            const SizedBox(width: 10),
            const Text('External Link'),
          ],
        ),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('You are about to leave this app and visit an external site.'),
              SizedBox(height: 10),
              Text('Do you want to continue?'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          FilledButton(
            child: const Text('Continue'),
            onPressed: () {
              Navigator.of(context).pop();
              _launchURL(context);
            },
          ),
        ],
      );
    },
  );
}

