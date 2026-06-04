import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';


import 'package:new_version_plus/new_version_plus.dart';

import '../constants.dart';
import '../helpers/analytics_helper.dart';
import '../providers.dart';
import '../screens/dx5ve_social/social_feed.dart';
import '../screens/dx5veScreens/eventSpeakersScreen.dart';
import '../screens/dx5veScreens/partners_screen.dart';
import '../screens/dx5veScreens/event_sessions_screen.dart';
import '../screens/dx5veScreens/sponsors_screen.dart';
import '../screens/dx5veScreens/dx5veAttendeesScreen.dart';
import '../screens/dx5veScreens/eventAgendaScreen.dart';
import '../screens/contact_scanning/getContact.dart';
import '../screens/feedback_page.dart';
import '../screens/rewardsPage.dart';
import '../map_screen.dart';
import '../testScreen.dart';
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
  bool _hasCheckedVersion = false;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasCheckedVersion) {
        _hasCheckedVersion = true;
        checkVersion();
      }
    });
  }
  Future<void> checkVersion() async {
    try {
      final newVersion = NewVersionPlus(
        androidId: 'com.cioafrica.dx5veevents',
        iOSId: 'com.cioafrica.dx5veevents',
        androidHtmlReleaseNotes: true,
      );

      debugPrint("Checking for app updates...");
      final version = await newVersion.getVersionStatus();


      if (version != null) {
        debugPrint("Version check successful!");
        debugPrint("Local version: ${version.localVersion}");
        debugPrint("Store version: ${version.storeVersion}");
        debugPrint("Can update: ${version.canUpdate}");
        debugPrint("Release notes: ${version.releaseNotes}");

        // Check if widget is still mounted before showing UI
        if (!mounted) return;

        // Show update dialog if there's an update available
        if (version.canUpdate) {
          debugPrint("Update available! Showing dialog...");
          newVersion.showUpdateDialog(
            context: context,
            versionStatus: version,
            dialogTitle: 'Update Available',
            dialogText: 'A new version of the app is available. Please update to get the latest features.',
            updateButtonText: 'Update Now',
            dismissButtonText: 'Later',
          );
        } else {
          debugPrint("App is up to date!");
        }
      } else {
        debugPrint("Could not fetch version info - version is null");
      }
    } catch (e) {
      debugPrint("Error fetching version info: $e");
      // Optional: Show a debug message in development
      if (mounted) {
        debugPrint("Version check failed silently");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Hero Section with improved overlay for better text readability
              Stack(
                children: [
                  // Cover Image
                  Image.asset(
                    "assets/images/themes/bfsi_landscape.png",
                    width: screenWidth,
                   // height: screenHeight * 0.3, // Made taller for more visual impact
                    fit: BoxFit.contain,
                  ),
                  // Gradient overlay for better text visibility


                ],
              ),
              // App Sponsor Section
              // Container(
              //   margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(12),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withOpacity(0.08),
              //         blurRadius: 10,
              //         offset: const Offset(0, 2),
              //       ),
              //     ],
              //   ),
              //   child: Column(
              //     children: [
              //       Text(
              //         "APP SPONSOR",
              //         style: TextStyle(
              //           fontSize: 11,
              //           fontWeight: FontWeight.w600,
              //           letterSpacing: 1.2,
              //           color: Colors.grey[600],
              //         ),
              //       ),
              //       const SizedBox(height: 12),
              //       SizedBox(
              //         height: 50,
              //         child: Image.asset(
              //           "assets/images/sponsors/mbcom.png",
              //           fit: BoxFit.contain,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              const Divider(),

              // Main Navigation Grid - Redesigned with card approach
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildFeatureCard(
                          context: context,
                         title:  'Agenda',
                        iconPath:   'assets/icons/agenda.png',
                        color:   kConnectedGreen,
                        screen:   EventAgendaScreen(
                            eventID: widget.eventID,
                            eventDay: widget.eventDay,
                            eventMonth: widget.eventMonth,
                            eventYear: widget.eventYear,
                            eventLocation: widget.eventLocation,
                            eventDayOfWeek: widget.eventDayOfWeek,
                            eventName: 'AGENDA',
                          ),
                       analyticsAction:    'agenda_page_opened',
                        ),
                        const SizedBox(width: 12),
                        _buildFeatureCard(
                         context:  context,
                         title:  'Networking',
                          iconPath: 'assets/icons/attendee.png',
                          color: kConnectedOrange,
                        screen:   AttendeesScreen(
                            eventID: widget.eventID,


                          ),
                          analyticsAction: 'attendees_page_opened',
                        ),
                      ],
                    ),
                    verticalSpace(height: 12),
                    Row(
                      children: [
                        _buildFeatureCard(
                         context:  context,
                         title:  'Venue Map',
                         iconPath:  'assets/icons/map.png',
                         color:  kConnectedBlue,
                         screen:  MapScreen(),
                         analyticsAction:  'map_screen_opened',
                        ),
                       //  _buildFeatureCard(
                       //  context:   context,
                       // title:    'Social',
                       // iconPath:    'assets/icons/social-media.png',
                       //  color:   kConnectedGreen,
                       //  screen:   const SocialFeed(),
                       // analyticsAction:    'social_page_opened',
                       //  ),
                        const SizedBox(width: 12),
                        _buildFeatureCard(
                         context:  context,
                        title:   'QR Scanner',
                         iconPath:  'assets/icons/scanner.png',
                         color:  kConnectedRed,
                         screen:  GetContact(ownerID: profileProvider.userID!),
                        analyticsAction:   'contact_scanner_page_opened',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFeatureCard(
                       context:    context,
                        title:   'Speakers',
                       iconPath:    'assets/icons/speaker.png',
                       color:    kConnectedBlue,
                        screen:   EventSpeakersScreen(eventID: widget.eventID),
                        analyticsAction:   'speakers_page_opened',
                        ),
                        const SizedBox(width: 12),
                        _buildFeatureCard(
                         context:  context,
                          title: 'Sponsors',
                         iconPath:  'assets/icons/sponsors.png',
                          color: kConnectedOrange,
                        screen:   CISOSponsorsScreen(eventID: widget.eventID),
                         analyticsAction:  'sponsors_page_opened',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [

                         _buildFeatureCard(
                          context: context,
                         title:  'Feedback',
                        iconPath:   'assets/icons/feedback.png',
                         color:  kConnectedOrange,
                          screen:  FeedbackPage(
                            eventID: widget.eventID,
                             attendeeID: profileProvider.profileId!,
                             attendeeName: "${profileProvider.firstName} ${profileProvider.lastName}",
                         
                          ),
                          analyticsAction: 'feedback_page_opened',
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
    );

  }

  // Enhanced feature card widget
  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String iconPath,
    required Color color,
    required Widget screen,
    required String analyticsAction,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () async{
          await   Dx5veAnalytics().logdx5veEvent(eventName: analyticsAction);

          PersistentNavBarNavigator.pushNewScreen(
            context,
            screen:  screen,
            withNavBar: false,
            pageTransitionAnimation: PageTransitionAnimation.slideRight,
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

