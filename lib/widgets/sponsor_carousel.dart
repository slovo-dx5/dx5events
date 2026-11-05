import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../constants.dart';
import '../helpers/analytics_helper.dart';
import '../screens/dx5veScreens/sponsors_screen.dart';
import '../services/event_sponsors_service.dart';
import 'app_sponsor.dart';

/// Home page: the app sponsor first, then the event's top-tier sponsors
/// ([kCarouselSponsorTiers]), auto-advancing every 4 seconds. Until the
/// sponsor list loads (or if it fails) only the app sponsor slide shows.
class SponsorCarousel extends StatefulWidget {
  const SponsorCarousel({super.key, required this.eventID});

  final String eventID;

  @override
  State<SponsorCarousel> createState() => _SponsorCarouselState();
}

class _SponsorCarouselState extends State<SponsorCarousel> {
  static const _logoHeight = 100.0;

  final _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;
  List<EventSponsor> _sponsors = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await EventSponsorsService.instance.load(widget.eventID);
      if (!mounted) return;
      setState(() {
        _sponsors = all.sponsors
            .where((s) => kCarouselSponsorTiers.contains(s.category.toLowerCase()))
            // The app sponsor already has its own slide.
            .where((s) => !(AppSponsor.enabled &&
                (s.data.sponsorName ?? '').toLowerCase().contains(AppSponsor.nameMatch)))
            .toList()
          // Highest tier first, then the event's own order within a tier.
          ..sort((a, b) {
            final byTier = kCarouselSponsorTiers
                .indexOf(a.category.toLowerCase())
                .compareTo(kCarouselSponsorTiers.indexOf(b.category.toLowerCase()));
            return byTier != 0 ? byTier : a.order.compareTo(b.order);
          });
      });
      _startTimer();
    } catch (e) {
      debugPrint('SponsorCarousel: failed to load sponsors: $e');
    }
  }

  int get _count => (AppSponsor.enabled ? 1 : 0) + _sponsors.length;

  void _startTimer() {
    _timer?.cancel();
    if (_count < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage((_page + 1) % _count,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = _count;
    if (count == 0) return const SizedBox.shrink();
    // Card = padding 26 + label + gap 10 + logo (+ a little slack). The
    // label grows with the system text size, so size the slot from it.
    final height = 40 + _logoHeight + MediaQuery.textScalerOf(context).scale(18);
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Column(
        children: [
          SizedBox(
            height: height,
            // A swipe restarts the countdown so the carousel doesn't jump
            // right after the user lands on a slide.
            child: NotificationListener<ScrollStartNotification>(
              onNotification: (n) {
                if (n.dragDetails != null) _startTimer();
                return false;
              },
              child: PageView.builder(
                controller: _controller,
                itemCount: count,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AppSponsor.enabled && i == 0
                      ? const AppSponsorSlide(placement: 'home_carousel', logoHeight: _logoHeight)
                      : _sponsorSlide(_sponsors[i - (AppSponsor.enabled ? 1 : 0)]),
                ),
              ),
            ),
          ),
          if (count > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < count; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? Colors.black54 : Colors.black12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sponsorSlide(EventSponsor s) {
    return GestureDetector(
      onTap: () async {
        await Dx5veAnalytics().logdx5veEvent(eventName: 'sponsor_carousel_tap');
        if (!mounted) return;
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: CISOSponsorsScreen(eventID: widget.eventID),
          withNavBar: false,
          pageTransitionAnimation: PageTransitionAnimation.slideRight,
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'EVENT SPONSOR',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: _logoHeight,
              child: CachedNetworkImage(
                imageUrl: s.logoUrl,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => Center(
                  child: Text(
                    s.data.sponsorName ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
