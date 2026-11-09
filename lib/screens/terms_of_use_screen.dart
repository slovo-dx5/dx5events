import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../dioServices/base_url.dart';

/// In-app Terms of Use. The content is plain data below ([_sections]) so it
/// can be revised without touching the layout. When it changes, bump
/// [TermsOfUseScreen.lastUpdated].
///
/// Each section matches something the app really does (see the comments on
/// each), so check the matching feature before changing what a section says.
class TermsOfUseScreen extends StatefulWidget {
  const TermsOfUseScreen({super.key, this.focus});

  /// Section to open and scroll to, e.g. [TermsSection.shop] from checkout.
  final TermsSection? focus;

  static const String lastUpdated = '9 November 2026';
  static const String operator = 'DX5ve';
  static const String contactEmail = 'dev@dx5ve.com';

  static Future<void> open(BuildContext context, {TermsSection? focus}) {
    return Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      builder: (_) => TermsOfUseScreen(focus: focus),
    ));
  }

  @override
  State<TermsOfUseScreen> createState() => _TermsOfUseScreenState();
}

enum TermsSection {
  about,
  account,
  badge,
  scanner,
  gallery,
  faceSearch,
  social,
  shop,
  rewards,
  harry,
  map,
  notifications,
  content,
  conduct,
  general,
}

class _Section {
  const _Section(this.id, this.icon, this.title, this.paragraphs);
  final TermsSection id;
  final IconData icon;
  final String title;
  final List<String> paragraphs;
}

const _o = TermsOfUseScreen.operator;
const _mail = TermsOfUseScreen.contactEmail;

const List<_Section> _sections = [
  _Section(TermsSection.about, Icons.info_outline_rounded, 'About these terms', [
    'This app is run by $_o for the events it lists, such as CIO100 and the '
        'Africa Channel Leaders Summit. By signing in or using the app you '
        'agree to these terms. If you do not agree, please do not use the app.',
    'How we handle your personal data is explained in our Privacy Policy, '
        'which forms part of these terms. We process personal data in line '
        'with the Kenya Data Protection Act, 2019.',
  ]),
  // eventLogin.dart / eventOTP.dart: email must be on the attendee list.
  _Section(TermsSection.account, Icons.person_outline_rounded, 'Your account', [
    'You sign in with the email address you registered with for the event, '
        'using a one-time code we send to it. The app is for registered '
        'attendees, speakers, sponsors and organisers only.',
    'Keep your sign-in codes private and do not let anyone else use the app '
        'as you. Make sure the details on your profile are accurate. Tell us '
        'if you think someone else has used your account.',
  ]),
  // profile_screen.dart _buildQrCodeSection; getContact.dart reads it back.
  _Section(TermsSection.badge, Icons.qr_code_2_rounded, 'Your profile and digital badge', [
    'Your profile shows a QR code that works as your digital badge. When '
        'another attendee or an exhibitor scans your badge (printed or in the '
        'app), they receive your name, company, job title, email address and '
        'phone number so they can follow up with you.',
    'Only show or share your badge with people you are happy to exchange '
        'contact details with. Your profile, including your photo, is also '
        'visible to other attendees in the attendee list.',
  ]),
  // getContact.dart + saveContact.dart: device contact insert + DB record,
  // points award, booth crawl signal.
  _Section(TermsSection.scanner, Icons.qr_code_scanner_rounded, 'Contact scanner', [
    'The scanner uses your camera to read event badges. Scan a badge only '
        'when its holder has agreed to share their details with you.',
    'A scanned contact is saved to your phone\'s contacts (with your '
        'permission) and recorded in your app account together with any note '
        'you add. Scans may also earn points, and scanning a booth counts '
        'towards booth challenges.',
    'Use contacts you collect only for genuine professional follow-up '
        'related to the event. Do not sell them, add them to bulk marketing '
        'lists or use them to spam or harass anyone. Once a contact is saved '
        'on your phone, you are responsible for how you keep and use it.',
  ]),
  // event_gallery_screen.dart, photo_viewer_screen.dart (download).
  _Section(TermsSection.gallery, Icons.photo_library_outlined, 'Event photo gallery', [
    'Photos and videos are taken at our events by official photographers. '
        'By attending you accept that you may appear in them, and that they '
        'may be shown in the app gallery and used to promote our events.',
    'You may view, download and share gallery photos for personal, '
        'non-commercial use, such as on your own social media, ideally '
        'crediting the event. You may not sell them, use them in advertising, '
        'or edit them in a way that misrepresents the people in them, without '
        'our written permission. Copyright stays with $_o and its '
        'photographers.',
    'If you would like a photo of you removed from the gallery, email '
        '$_mail with a link or screenshot and we will take it down.',
  ]),
  // face_search_screen.dart + pix face-search endpoint (selfie discarded).
  _Section(TermsSection.faceSearch, Icons.face_retouching_natural_outlined, 'Find my photos (face search)', [
    'Face search is optional. If you use it, the selfie you take is sent '
        'securely to our gallery service, compared against the faces in that '
        'event\'s photos, and then discarded. It is used for that one search '
        'only and is not stored by the app or the gallery.',
    'Only search with a photo of yourself. Do not use face search to find '
        'photos of other people.',
  ]),
  // dx5ve_social (posts, comments, reports, blocks, profanity filter) and
  // chats (Firestore messages, photo messages, push).
  _Section(TermsSection.social, Icons.forum_outlined, 'Social feed, comments and chat', [
    'You are responsible for what you post, comment or send in chat, '
        'including photos. Only share content you have the right to share, '
        'and photos of other people only with their agreement.',
    'You keep ownership of your content, but you allow $_o to display it in '
        'the app to other attendees and, for public feed posts, to feature it '
        'in event coverage. Messages and photos you send in chat are stored so '
        'that you and the person you are chatting with can see them, and the '
        'recipient gets a notification.',
    'Be respectful. No harassment, hate speech, sexual or violent content, '
        'spam, selling or misleading information. Posts are checked by a '
        'language filter, and you can report or block anyone. We may remove '
        'content and suspend accounts that break these terms.',
  ]),
  // shop: Flow 1 prices server-side, Pesapal hosted checkout, stock badges.
  _Section(TermsSection.shop, Icons.shopping_bag_outlined, 'Shop', [
    'Prices are shown and charged in Kenyan Shillings (KES). The price you '
        'pay is the one confirmed at checkout. Stock labels such as "Only 3 '
        'left" or "Selling fast" are a guide; availability is confirmed when '
        'you pay.',
    'Payments are processed by Pesapal on its secure page. $_o does not see '
        'or store your card or mobile money details. Your order is confirmed '
        'once Pesapal confirms the payment, and you receive a receipt by '
        'email. Your order history is in the app.',
    'Orders are collected at the merchandise desk at the venue during the '
        'event: show your order confirmation or receipt. Delivery can be '
        'arranged on request; any delivery cost is agreed with you before it '
        'is sent.',
    'Refunds: if an item is faulty or not what you ordered, we will replace '
        'it or refund you. Size exchanges are available at the desk while '
        'stock lasts. We do not offer refunds for a change of mind. This does '
        'not affect your rights under Kenyan consumer protection law.',
  ]),
  // rewardsPage.dart, gamification backend (leaderboard_freeze_at).
  _Section(TermsSection.rewards, Icons.emoji_events_outlined, 'Points, challenges and leaderboard', [
    'You earn points for taking part, for example by scanning contacts, '
        'visiting booths and completing challenges. Points have no cash value '
        'and cannot be transferred, sold or exchanged for money.',
    'We may correct points awarded in error and remove points or entries '
        'earned by cheating, such as scanning badges without meeting people '
        'or using more than one account. The leaderboard may be frozen before '
        'prize-giving. Prizes, if any, are at $_o\'s discretion and its '
        'decision is final.',
  ]),
  // services/harry: Anthropic / Google Gemini / OpenAI-compatible brains,
  // speech_to_text for voice.
  _Section(TermsSection.harry, Icons.smart_toy_outlined, 'Harry, the AI assistant', [
    'Harry answers questions about the event using artificial intelligence. '
        'To do that, your questions and the event information needed to '
        'answer them are sent to third-party AI providers.',
    'AI answers can be wrong or out of date. Check important details such '
        'as session times and rooms against the agenda in the app. Do not '
        'share passwords, payment details or other sensitive personal '
        'information with Harry.',
    'If you use voice, your speech is turned into text by your phone\'s '
        'speech recognition service.',
  ]),
  // venue_map_screen.dart: geolocator, position shown on device only.
  _Section(TermsSection.map, Icons.map_outlined, 'Venue map and location', [
    'The venue map can show where you are, if you allow location access. '
        'Your location is used on your phone to place you on the map and is '
        'not sent to us. You can turn location access off at any time in '
        'your phone\'s settings; the map still works without it.',
  ]),
  _Section(TermsSection.notifications, Icons.notifications_none_rounded, 'Notifications', [
    'With your permission we send push notifications about the agenda, '
        'announcements, messages and partner events. You can turn them off in '
        'your phone\'s settings.',
  ]),
  _Section(TermsSection.content, Icons.slideshow_outlined, 'Agendas, presentations and event content', [
    'Agendas, speaker details, presentations and other event content are '
        'provided for your personal reference. Presentations belong to their '
        'speakers or companies; do not republish them without permission.',
    'Agendas can change at short notice. We try to keep the app up to date, '
        'but the information on site takes priority.',
  ]),
  _Section(TermsSection.conduct, Icons.gpp_maybe_outlined, 'Acceptable use', [
    'Do not misuse the app: no attempts to access other people\'s accounts '
        'or data, to interfere with or reverse-engineer the app or its '
        'services, to scrape attendee information, or to use the app for '
        'anything unlawful.',
  ]),
  _Section(TermsSection.general, Icons.gavel_rounded, 'Changes, liability and contact', [
    'The app is provided as it is. We work to keep it available and '
        'accurate but cannot guarantee it will always be error-free or '
        'uninterrupted. To the extent the law allows, $_o is not liable for '
        'indirect losses arising from your use of the app.',
    'We may update these terms; the date at the top shows the latest '
        'version, and continuing to use the app means you accept the changes. '
        'These terms are governed by the laws of Kenya.',
    'Questions, removal requests or reports: email $_mail.',
  ]),
];

class _TermsOfUseScreenState extends State<TermsOfUseScreen> {
  final Map<TermsSection, GlobalKey> _keys = {
    for (final s in _sections) s.id: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    final focus = widget.focus;
    if (focus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[focus]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic);
        }
      });
    }
  }

  Future<void> _openPrivacy() async {
    final ok = await launchUrl(Uri.parse(BaseURL.PrivacyUrl),
        mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the Privacy Policy.')),
      );
    }
  }

  Future<void> _email() async {
    await launchUrl(Uri(
      scheme: 'mailto',
      path: TermsOfUseScreen.contactEmail,
      query: 'subject=Terms of Use question',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Use'), centerTitle: true),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text('Last updated ${TermsOfUseScreen.lastUpdated}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(
              'The short version: use the app to make the most of the event, '
              'respect other attendees and their details, and read the '
              'sections that apply to what you use. Tap a section to read it.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 16),
            for (final s in _sections)
              _SectionTile(
                key: _keys[s.id],
                section: s,
                initiallyExpanded: s.id == widget.focus,
              ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _openPrivacy,
              icon: const Icon(Icons.privacy_tip_outlined),
              label: const Text('Read the Privacy Policy'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kCIOPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _email,
              icon: const Icon(Icons.mail_outline_rounded),
              label: const Text('Contact ${TermsOfUseScreen.contactEmail}'),
              style: TextButton.styleFrom(foregroundColor: kCIOPurple),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile(
      {super.key, required this.section, this.initiallyExpanded = false});

  final _Section section;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(section.icon, color: kCIOPurple),
        title: Text(section.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        shape: const Border(),
        collapsedShape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in section.paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(p,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
            ),
        ],
      ),
    );
  }
}
