import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../services/event_sponsors_service.dart';
import '../../widgets/cio_bottomsheets.dart';
import '../../widgets/app_sponsor.dart';
import '../../widgets/sponsor_widget.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CISOSponsorsScreen extends StatefulWidget {
  final String eventID;
  const CISOSponsorsScreen({required this.eventID, super.key});

  @override
  State<CISOSponsorsScreen> createState() => _CISOSponsorsScreenState();
}

class _CISOSponsorsScreenState extends State<CISOSponsorsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Future<EventSponsors> _dataFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dataFuture = EventSponsorsService.instance.load(widget.eventID);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MEET OUR SPONSORS',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        centerTitle: true,
        elevation: 10,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'SPONSORS'),
            Tab(text: 'EXHIBITORS'),
          ],
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<EventSponsors>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading data: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('No sponsors available'));
            }
            final result = snapshot.data!;
            return TabBarView(
              controller: _tabController,
              children: [
                _SponsorsTab(
                  sponsors: result.sponsors,
                  categoryOrder: EventSponsorsService.categoryOrder,
                ),
                _ExhibitorsTab(exhibitors: result.exhibitors),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sponsors tab — grouped by category in canonical order
// ---------------------------------------------------------------------------

class _SponsorsTab extends StatelessWidget {
  final List<EventSponsor> sponsors;
  final List<String> categoryOrder;

  const _SponsorsTab(
      {required this.sponsors, required this.categoryOrder});

  @override
  Widget build(BuildContext context) {
    // The app sponsor gets its own headline card, so drop its regular entry
    // if the event also lists it in a tier.
    final tiered = AppSponsor.enabled
        ? sponsors
            .where((s) => !(s.data.sponsorName ?? '')
                .toLowerCase()
                .contains(AppSponsor.nameMatch))
            .toList()
        : sponsors;

    if (tiered.isEmpty && !AppSponsor.enabled) {
      return const Center(child: Text('No sponsors available'));
    }

    // Group by category, preserving per-category order from the sorted list
    final grouped = <String, List<EventSponsor>>{};
    for (final s in tiered) {
      grouped.putIfAbsent(s.category, () => []).add(s);
    }

    // Build section list: degree tiers (CIO100's '360', '180', '90', '45')
    // highest first, then known named categories (in canonical order),
    // matched case-insensitively, then any remaining categories appended so
    // nothing is ever silently dropped.
    final canonicalLower = categoryOrder.map((c) => c.toLowerCase()).toList();
    final sections = <MapEntry<String, List<EventSponsor>>>[];
    final usedKeys = <String>{};

    final degreeKeys = grouped.keys
        .where((k) => int.tryParse(k.trim()) != null && grouped[k]!.isNotEmpty)
        .toList()
      ..sort((a, b) => int.parse(b.trim()).compareTo(int.parse(a.trim())));
    for (final key in degreeKeys) {
      sections.add(MapEntry(key, grouped[key]!));
      usedKeys.add(key);
    }

    for (final canonical in canonicalLower) {
      for (final entry in grouped.entries) {
        if (entry.key.toLowerCase() == canonical && entry.value.isNotEmpty) {
          sections.add(MapEntry(entry.key, entry.value));
          usedKeys.add(entry.key);
        }
      }
    }
    // Append any categories not present in the canonical order.
    for (final entry in grouped.entries) {
      if (!usedKeys.contains(entry.key) && entry.value.isNotEmpty) {
        sections.add(MapEntry(entry.key, entry.value));
      }
    }

    final lead = AppSponsor.enabled ? 1 : 0;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: sections.length + lead,
      itemBuilder: (context, i) => i < lead
          ? const AppSponsorFeatureCard()
          : _CategorySection(
              category: sections[i - lead].key,
              sponsors: sections[i - lead].value,
            ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<EventSponsor> sponsors;

  const _CategorySection(
      {required this.category, required this.sponsors});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            category.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFFCCCCCC),
              letterSpacing: 2,
            ),
          ),
        ),
        ...sponsors.map(
          (s) => sponsorWidget(
            context: context,
            sponsorAsset: s.logoUrl,
            degree: category.toUpperCase(),
            sponsorName: s.data.sponsorName ?? '',
            sponsorBio: s.data.about ?? '',
            sponsorURL: s.websiteUrl,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Exhibitors tab — grid of logo cards, matching ExhibitorsSection.svelte
// ---------------------------------------------------------------------------

class _ExhibitorsTab extends StatelessWidget {
  final List<EventSponsor> exhibitors;

  const _ExhibitorsTab({required this.exhibitors});

  @override
  Widget build(BuildContext context) {
    if (exhibitors.isEmpty) {
      return const Center(child: Text('No exhibitors available'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: exhibitors.length,
      itemBuilder: (context, i) =>
          _ExhibitorCard(exhibitor: exhibitors[i]),
    );
  }
}

class _ExhibitorCard extends StatelessWidget {
  final EventSponsor exhibitor;

  const _ExhibitorCard({required this.exhibitor});

  @override
  Widget build(BuildContext context) {
    final hasDetail =
        (exhibitor.data.about?.isNotEmpty == true) ||
        exhibitor.websiteUrl.isNotEmpty;

    return GestureDetector(
      onTap: hasDetail
          ? () => defaultScrollableBottomSheet(
                context,
                exhibitor.data.sponsorName ?? '',
                SponsorBottomSheet(
                  SponsorImage: exhibitor.logoUrl,
                  SponsorAbout: exhibitor.data.about ?? '',
                  SponsorName: exhibitor.data.sponsorName ?? '',
                  SponsorURL: exhibitor.websiteUrl,
                ),
              )
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.network(
                exhibitor.logoUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              exhibitor.data.sponsorName ?? '',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
