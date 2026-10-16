import 'package:flutter/material.dart';

import '../constants.dart';
import '../helpers/helper_functions.dart';
import '../services/activity_logger.dart';

/// The event's exclusive app sponsor, and every placement it gets in the app.
///
/// Everything sponsor-specific lives here, so the next event's sponsor is a
/// change to this class and its assets only. Set [enabled] to false to remove
/// the sponsor from every placement at once.
///
/// The sponsor's phone number is not hard-coded: it comes from the Directus
/// `sponsor_contact` collection and is cached under [kSponsorPhone] by
/// `mainNavigationPage.dart`.
///
/// Emails carry the sponsor too, but are built server-side: see
/// `functions/meeting_emails.js` and `tool/directus_flows/flow3_receipt.js`.
class AppSponsor {
  AppSponsor._();

  static const bool enabled = true;

  static const String name = 'MBCOM Technologies';
  static const String shortName = 'MBCOM';

  /// Wide lockup (MBCOM × VMware), for banners and the sponsors page.
  static const String logo = 'assets/images/sponsors/mbcom.png';

  /// Square mark, for avatar-sized placements.
  static const String profile = 'assets/images/sponsors/mbcom_profile.png';

  /// Hosted copy of [logo], for the places that cannot use app assets.
  static const String logoUrl =
      'https://subscriptions.cioafrica.co/assets/6990f48c-b77b-4fd0-bc27-36e548876d51';

  /// MBCOM red, sampled from the logo.
  static const Color brand = Color(0xFFC92030);

  /// In the attendees list, the sponsor card follows every this many attendees.
  static const int attendeeInterval = 10;

  /// Case-insensitive fragment used to drop the sponsor's own entry from the
  /// regular sponsor tiers, so it is not listed twice.
  static const String nameMatch = 'mbcom';

  /// One-line pitch, shown in the detail sheet and the pinned feed post.
  static const String pitch =
      'MBCOM Technologies is the official app sponsor of this event. Talk to '
      'their team about modernising your infrastructure with VMware by Broadcom.';

  // ── Booth challenge ───────────────────────────────────────────────────────

  /// Content of the QR code at the sponsor's booth. Follows the existing
  /// `sponsor-<name>` convention, so Get Contact already accepts it and
  /// records the lead in `sponsordata`.
  static const String boothCode = 'sponsor-mbcom';

  /// Shown in the booth copy. Must match the "MBCOM booth" rule's points in
  /// `point_actions` (trigger sponsor_booth_scan, match target_type
  /// app_sponsor) — the server awards it, this is only the label.
  static const int boothPoints = 100;

  /// Where to find the booth, shown on the venue map. Null leaves the chip as
  /// a plain invitation.
  static const String? boothLocation = null;

  /// Appended to reminder notifications.
  static String get reminderCredit =>
      enabled ? ' · Brought to you by $shortName' : '';

  // ── Reporting ─────────────────────────────────────────────────────────────

  static final Set<String> _seen = {};

  /// Records that a placement was shown — once per placement per app run, so
  /// the numbers read as "people who saw it", not scroll noise.
  static void impression(String placement) {
    if (!enabled || !_seen.add(placement)) return;
    ActivityLogger.instance.log(
      action: ActivityAction.sponsorImpression,
      targetType: 'app_sponsor',
      targetId: placement,
    );
  }

  /// Records a tap on a placement.
  static void tap(String placement) {
    if (!enabled) return;
    ActivityLogger.instance.log(
      action: ActivityAction.sponsorTap,
      targetType: 'app_sponsor',
      targetId: placement,
    );
  }
}

/// Logs one [AppSponsor.impression] for [placement] when first built.
class _Seen extends StatefulWidget {
  const _Seen(this.placement, this.child);

  final String placement;
  final Widget child;

  @override
  State<_Seen> createState() => _SeenState();
}

class _SeenState extends State<_Seen> {
  @override
  void initState() {
    super.initState();
    AppSponsor.impression(widget.placement);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The "APP SPONSOR" label used by several placements.
class _SponsorLabel extends StatelessWidget {
  const _SponsorLabel({this.center = false});

  final bool center;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        const Icon(Icons.star_rounded, size: 14, color: AppSponsor.brand),
        const SizedBox(width: 4),
        Text(
          'APP SPONSOR',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppSponsor.brand.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}

/// Opens the sponsor's detail sheet: logo, pitch, and a call button when
/// Directus has a contact number. [placement] says which placement was tapped.
Future<void> showAppSponsorSheet(BuildContext context,
    {required String placement}) async {
  AppSponsor.tap(placement);
  final phone = await getStringPref(kSponsorPhone);
  if (!context.mounted) return;
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const _SponsorLabel(center: true),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: Image.asset(AppSponsor.logo, fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),
            Text(
              AppSponsor.pitch,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.45, color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),
            Text(
              'Visit their booth and scan the QR code with Get Contact for '
              '${AppSponsor.boothPoints} reward points.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, height: 1.4, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            if (phone.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    AppSponsor.tap('sheet_call');
                    launchPhoneCall(phoneNumber: phone);
                  },
                  icon: const Icon(Icons.call_rounded, size: 20),
                  label: Text('Call the ${AppSponsor.shortName} team',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppSponsor.brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
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

/// Booth challenge: shown after the sponsor's booth QR code is scanned.
Future<void> showAppSponsorBoothReward(BuildContext context) {
  AppSponsor.impression('booth_reward');
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 48,
              child: Image.asset(AppSponsor.logo, fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),
            Text(
              'Thanks for visiting ${AppSponsor.shortName}!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppSponsor.brand.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '+${AppSponsor.boothPoints} reward points',
                style: TextStyle(
                  color: AppSponsor.brand,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The ${AppSponsor.shortName} team has your details and will be in touch.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppSponsor.brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Home page: the sponsor lockup directly below the event banner.
class AppSponsorBanner extends StatelessWidget {
  const AppSponsorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppSponsor.enabled) return const SizedBox.shrink();
    return _Seen(
      'home_banner',
      GestureDetector(
        onTap: () => showAppSponsorSheet(context, placement: 'home_banner'),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppSponsor.brand.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              const _SponsorLabel(center: true),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: Image.asset(AppSponsor.logo, fit: BoxFit.contain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Attendees list: the sponsor shown as if it were an attendee, with a
/// sponsor-coloured Connect button. Same 85px height as `attendeeWidget`.
class AppSponsorAttendeeCard extends StatelessWidget {
  const AppSponsorAttendeeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _Seen(
      'attendee_list',
      SizedBox(
        height: 85,
        width: double.infinity,
        child: GestureDetector(
          onTap: () => showAppSponsorSheet(context, placement: 'attendee_list'),
          child: Card(
            elevation: 0.2,
            color: Color.alphaBlend(
                AppSponsor.brand.withOpacity(0.04), Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: AppSponsor.brand.withOpacity(0.18)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppSponsor.brand.withOpacity(0.35), width: 1.5),
                    ),
                    child: Image.asset(AppSponsor.profile, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppSponsor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 2),
                        _SponsorLabel(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 2,
                    child: IntrinsicWidth(
                      child: SizedBox(
                        height: 35,
                        child: ElevatedButton(
                          onPressed: () => showAppSponsorSheet(context,
                              placement: 'attendee_connect'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppSponsor.brand,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: const Text(
                            'Connect',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sponsors page: the headline card above every sponsor tier.
class AppSponsorFeatureCard extends StatelessWidget {
  const AppSponsorFeatureCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppSponsor.enabled) return const SizedBox.shrink();
    return _Seen(
      'sponsors_page',
      GestureDetector(
        onTap: () => showAppSponsorSheet(context, placement: 'sponsors_page'),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppSponsor.brand.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppSponsor.brand.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  color: AppSponsor.brand,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: const Text(
                  'EXCLUSIVE APP SPONSOR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                child: SizedBox(
                  height: 64,
                  child: Image.asset(AppSponsor.logo, fit: BoxFit.contain),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'Tap to learn more',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppSponsor.brand.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
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

/// A thin "<lead> [logo]" bar, e.g. "Agenda powered by". Used at the top of
/// the agenda, the gallery and Harry's chat.
class AppSponsorStrip extends StatelessWidget {
  const AppSponsorStrip({super.key, required this.lead, required this.placement});

  final String lead;
  final String placement;

  @override
  Widget build(BuildContext context) {
    if (!AppSponsor.enabled) return const SizedBox.shrink();
    return _Seen(
      placement,
      Material(
        color: Colors.white,
        child: InkWell(
          onTap: () => showAppSponsorSheet(context, placement: placement),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppSponsor.brand.withOpacity(0.12)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  lead,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 18,
                  child: Image.asset(AppSponsor.logo, fit: BoxFit.contain),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "App sponsored by [logo]" pill for full-screen surfaces (splash, login),
/// which have dark or busy backgrounds.
class AppSponsorBadge extends StatelessWidget {
  const AppSponsorBadge({super.key, required this.placement});

  final String placement;

  @override
  Widget build(BuildContext context) {
    if (!AppSponsor.enabled) return const SizedBox.shrink();
    return _Seen(
      placement,
      Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'App sponsored by',
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 0.6,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 26,
              child: Image.asset(AppSponsor.logo, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }
}

/// Social feed: a pinned welcome post from the sponsor, styled like a post.
class AppSponsorFeedPost extends StatelessWidget {
  const AppSponsorFeedPost({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppSponsor.enabled) return const SizedBox.shrink();
    return _Seen(
      'social_feed',
      Card(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppSponsor.brand.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppSponsor.brand.withOpacity(0.35), width: 1.2),
                    ),
                    child: Image.asset(AppSponsor.profile, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppSponsor.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14.5),
                        ),
                        Row(
                          children: [
                            Icon(Icons.push_pin, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 3),
                            Text('Pinned · App sponsor',
                                style: TextStyle(
                                    fontSize: 11.5, color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome! ${AppSponsor.pitch} Find us at our booth and scan the '
                'QR code for ${AppSponsor.boothPoints} reward points.',
                style: const TextStyle(fontSize: 14, height: 1.45),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox(
                  height: 44,
                  child: Image.asset(AppSponsor.logo, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      showAppSponsorSheet(context, placement: 'social_feed'),
                  style: TextButton.styleFrom(foregroundColor: AppSponsor.brand),
                  child: Text('Meet ${AppSponsor.shortName}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Venue map: a floating chip pointing people to the sponsor's booth. The map
/// itself is a third-party web page, so the pin cannot go inside it.
class AppSponsorMapChip extends StatelessWidget {
  const AppSponsorMapChip({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppSponsor.enabled) return const SizedBox.shrink();
    final where = AppSponsor.boothLocation;
    return _Seen(
      'venue_map',
      Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => showAppSponsorSheet(context, placement: 'venue_map'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppSponsor.brand.withOpacity(0.4)),
                  ),
                  child: Image.asset(AppSponsor.profile, fit: BoxFit.contain),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    where == null
                        ? 'Visit ${AppSponsor.shortName} at their booth'
                        : 'Visit ${AppSponsor.shortName} · $where',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppSponsor.brand,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
