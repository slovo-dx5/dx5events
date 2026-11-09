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
import '../screens/dx5veScreens/sponsors_screen.dart';
import '../screens/dx5veScreens/dx5veAttendeesScreen.dart';
import '../screens/dx5veScreens/eventAgendaScreen.dart';
import '../screens/contact_scanning/getContact.dart';
import '../screens/feedback_entry.dart';
import '../screens/gallery/event_gallery_screen.dart';
import '../services/gallery/gallery_notifications.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/venue_map/venue_map_screen.dart';
import '../services/gamification/gamification_service.dart';
import '../map_screen.dart';
import '../testScreen.dart';
import '../services/active_event/active_event.dart';
import '../services/active_event/active_event_service.dart';
import 'acls/acls_links.dart';
import 'acls/showdown_hero.dart';
import 'acls/signal_hijack_overlay.dart';
import 'cio_widgets.dart';
import 'event_image.dart';
import 'clickableBanner.dart';
import 'rewards_home_card.dart';
import 'shop_promo.dart';
import 'sponsor_carousel.dart';

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
      _maybeSignalHijack();
    });
    // The companion config may land after this screen is built (first
    // launch); try the intro again when it does.
    ActiveEventService.instance.addListener(_maybeSignalHijack);
    // Subscribe this device to new-photo pushes for the event being viewed.
    // Topic is keyed on the app event id; fire-and-forget.
    if (kGalleryFeatureEnabled) {
      GalleryNotifications.subscribeForEvent(widget.eventID);
    }
  }
  @override
  void dispose() {
    ActiveEventService.instance.removeListener(_maybeSignalHijack);
    super.dispose();
  }

  /// ACLS day: play the Signal Hijack intro once, only on the active event's
  /// home and only while it's the screen on top.
  void _maybeSignalHijack() {
    if (!mounted) return;
    if (widget.eventID != ActiveEventService.instance.current.id) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    SignalHijackOverlay.maybeShow(context);
  }

  /// "CIO100 · DAY 3": the active event's day number today (Nairobi time).
  String _mainEventDayLabel(ActiveEvent event) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    final day = DateTime(now.year, now.month, now.day)
            .difference(DateTime(
                event.dateFrom.year, event.dateFrom.month, event.dateFrom.day))
            .inDays +
        1;
    const name = 'CIO100';
    return day >= 1 ? '$name · DAY $day' : name;
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
    final activeEvent = context.watch<ActiveEventService>().current;

    return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Hero Section with improved overlay for better text readability
              Stack(
                children: [
                  // Cover Image
                  // Directus artwork for the app's active event; any other
                  // event keeps the bundled cover.
                  // On the companion (ACLS) day, CIO100 and ACLS share the
                  // banner; every other day it's the usual cover.
                  if (widget.eventID == activeEvent.id &&
                      context.watch<ActiveEventService>().isCompanionDay)
                    ShowdownHero(
                      cio: EventImage(
                        url: activeEvent.coverImageUrl,
                        fallbackAsset: ActiveEvent.bundledCoverImage,
                        fit: BoxFit.cover,
                      ),
                      cioLabel: _mainEventDayLabel(activeEvent),
                      onAclsTap: () => openCompanionAgenda(context),
                    )
                  else
                  EventImage(
                    url: widget.eventID == activeEvent.id
                        ? activeEvent.coverImageUrl
                        : null,
                    fallbackAsset: ActiveEvent.bundledCoverImage,
                    width: screenWidth,
                   // height: screenHeight * 0.3, // Made taller for more visual impact
                    fit: BoxFit.contain,
                  ),
                  // Gradient overlay for better text visibility


                ],
              ),
              // App sponsor plus top-tier event sponsors, below the banner.
              SponsorCarousel(eventID: widget.eventID),


              // Main Navigation Grid - Redesigned with card approach
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    ...() {
                      const showShop = kShopFeatureEnabled;
                      final showRewards = kRewardsFeatureEnabled &&
                          GamificationService.instance.isEnabled;
                      if (!showShop && !showRewards) return const <Widget>[];
                      // Both enabled: share one row to save vertical space;
                      // otherwise the single card keeps the full width.
                      final Widget banners = showShop && showRewards
                          ? Row(
                              children: [
                                const Expanded(child: ShopHomeCard(compact: true)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RewardsHomeCard(
                                    userID: profileProvider.userID,
                                    screenBuilder: (key) =>
                                        _rewardScreen(key, profileProvider),
                                    compact: true,
                                  ),
                                ),
                              ],
                            )
                          : showShop
                              ? const ShopHomeCard()
                              : RewardsHomeCard(
                                  userID: profileProvider.userID,
                                  screenBuilder: (key) =>
                                      _rewardScreen(key, profileProvider),
                                );
                      return [banners, const SizedBox(height: 12)];
                    }(),
                    ..._buildTileRows([
                      _buildFeatureCard(
                        context: context,
                        title: 'Agenda',
                        iconPath: 'assets/icons/agenda.png',
                        color: kConnectedGreen,
                        screen: EventAgendaScreen(
                          eventID: widget.eventID,
                          eventDay: widget.eventDay,
                          eventMonth: widget.eventMonth,
                          eventYear: widget.eventYear,
                          eventLocation: widget.eventLocation,
                          eventDayOfWeek: widget.eventDayOfWeek,
                          eventName: 'AGENDA',
                        ),
                        analyticsAction: 'agenda_page_opened',
                      ),
                      _buildFeatureCard(
                        context: context,
                        title: 'Networking',
                        iconPath: 'assets/icons/attendee.png',
                        color: kConnectedOrange,
                        screen: AttendeesScreen(eventID: widget.eventID),
                        analyticsAction: 'attendees_page_opened',
                      ),
                      _buildFeatureCard(
                        context: context,
                        title: 'QR Scanner',
                        iconPath: 'assets/icons/scanner.png',
                        color: kConnectedRed,
                        screen: GetContact(ownerID: profileProvider.userID!),
                        analyticsAction: 'contact_scanner_page_opened',
                      ),
                      _buildFeatureCard(
                        context: context,
                        title: 'Speakers',
                        iconPath: 'assets/icons/speaker.png',
                        color: kConnectedBlue,
                        screen: EventSpeakersScreen(eventID: widget.eventID),
                        analyticsAction: 'speakers_page_opened',
                      ),
                      _buildFeatureCard(
                        context: context,
                        title: 'Sponsors',
                        iconPath: 'assets/icons/sponsors.png',
                        color: kConnectedOrange,
                        screen: CISOSponsorsScreen(eventID: widget.eventID),
                        analyticsAction: 'sponsors_page_opened',
                      ),
                      if (kVenueMapFeatureEnabled)
                        _buildFeatureCard(
                          context: context,
                          title: 'Venue Map',
                          iconPath: 'assets/icons/map.png',
                          color: kConnectedBlue,
                          screen: const VenueMapScreen(),
                          analyticsAction: 'venue_map_opened',
                        ),
                      if (kGalleryFeatureEnabled)
                        _buildFeatureCard(
                          context: context,
                          title: 'Gallery',
                          iconPath: 'assets/icons/photo-gallery.png',
                          color: kNashPurple,
                          screen: EventGalleryScreen(
                            eventId: widget.eventID,
                            eventName: widget.eventName,
                          ),
                          analyticsAction: 'gallery_page_opened',
                        ),
                      _buildFeatureCard(
                        context: context,
                        title: 'Feedback',
                        iconPath: 'assets/icons/feedback.png',
                        color: kConnectedOrange,
                        screen: FeedbackEntry(eventID: widget.eventID),
                        analyticsAction: 'feedback_page_opened',
                      ),
                      _buildFeatureCard(
                        context: context,
                        title: 'Social',
                        iconPath: 'assets/icons/social-media.png',
                        color: kConnectedGreen,
                        screen: const SocialFeed(),
                        analyticsAction: 'social_page_opened',
                      ),
                    ]),


                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
    );

  }

  /// Screens a Rewards challenge card can open, keyed by the rule's
  /// `screen_name` in Directus. Unknown keys return null (card not tappable).
  Widget? _rewardScreen(String key, ProfileProvider profileProvider) {
    switch (key) {
      case 'agenda':
        return EventAgendaScreen(
          eventID: widget.eventID,
          eventDay: widget.eventDay,
          eventMonth: widget.eventMonth,
          eventYear: widget.eventYear,
          eventLocation: widget.eventLocation,
          eventDayOfWeek: widget.eventDayOfWeek,
          eventName: 'AGENDA',
        );
      case 'networking':
        return AttendeesScreen(eventID: widget.eventID);
      case 'scanner':
        final id = profileProvider.userID;
        return id == null ? null : GetContact(ownerID: id);
      case 'speakers':
        return EventSpeakersScreen(eventID: widget.eventID);
      case 'sponsors':
        return CISOSponsorsScreen(eventID: widget.eventID);
      case 'social':
        return const SocialFeed();
      case 'gallery':
        return kGalleryFeatureEnabled
            ? EventGalleryScreen(eventId: widget.eventID, eventName: widget.eventName)
            : null;
      case 'shop':
        return kShopFeatureEnabled ? const ShopScreen() : null;
      case 'feedback':
        return profileProvider.userID == null
            ? null
            : FeedbackEntry(eventID: widget.eventID);
      default:
        return null;
    }
  }

  /// Lays the menu tiles out three per row. A short last row is padded with
  /// empty slots so every tile keeps the same width.
  List<Widget> _buildTileRows(List<Widget> tiles) {
    const perRow = 3;
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += perRow) {
      final slots = <Widget>[];
      for (var j = i; j < i + perRow; j++) {
        if (j > i) slots.add(const SizedBox(width: 12));
        slots.add(j < tiles.length ? tiles[j] : const Expanded(child: SizedBox()));
      }
      if (i > 0) rows.add(const SizedBox(height: 12));
      rows.add(Row(children: slots));
    }
    return rows;
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
              // Tiles are a third of the width; shrink long titles to fit.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
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

