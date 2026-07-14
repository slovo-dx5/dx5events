import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../dioServices/base_url.dart';
import '../../dioServices/dioFetchService.dart';
import '../../models/eventModel.dart';
import '../../models/sponsor_data_model.dart';
import '../../widgets/cio_bottomsheets.dart';
import '../../widgets/sponsor_widget.dart';

// ---------------------------------------------------------------------------
// Data helpers
// ---------------------------------------------------------------------------

class _EnrichedSponsor {
  final SponsorData data;
  final String category;
  final int order;

  const _EnrichedSponsor({
    required this.data,
    required this.category,
    required this.order,
  });

  /// Resolves a bare Directus UUID to a full asset URL. If already a URL,
  /// returns as-is. Prefers transparent_logo over logo when present.
  String get logoUrl {
    final logo = data.transparent_logo ?? data.logo ?? '';
    return logo.startsWith('http') ? logo : '${BaseURL.Baseurl}/assets/$logo';
  }

  String get websiteUrl =>
      (data.websites?.isNotEmpty == true) ? (data.websites!.first.link ?? '') : '';
}

class _SponsorsResult {
  final List<_EnrichedSponsor> sponsors;
  final List<_EnrichedSponsor> exhibitors;

  const _SponsorsResult({required this.sponsors, required this.exhibitors});
}

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
  late final Future<_SponsorsResult> _dataFuture;

  // Canonical display order, matching SponsorsSection.svelte
  static const _categoryOrder = [
    'simba', 'ndovu', 'kifaru', 'twiga', 'nyati', 'chui', 'duma', 'kiboko',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_SponsorsResult> _loadData() async {
    // 1. Fetch event to get sponsor associations (key + category + order)
    final eventResponse =
        await DioFetchService().fetchEvents(eventID: widget.eventID);
    final Map<String, dynamic> eventData = eventResponse.data['data'];

    final rawSponsors = eventData['sponsors'] as List<dynamic>? ?? [];
    if (rawSponsors.isEmpty) {
      return const _SponsorsResult(sponsors: [], exhibitors: []);
    }

    final associations =
        rawSponsors.map((s) => SponsorAssociation.fromJson(s)).toList();

    // 2. Record original order and category from the junction records
    final orderMap = <int, int>{};
    final categoryMap = <int, String>{};
    for (var i = 0; i < associations.length; i++) {
      final id = associations[i].sponsor.key;
      orderMap[id] = i;
      categoryMap[id] = associations[i].category;
    }

    // 3. Bulk-fetch sponsor details in a single API call
    final ids = associations.map((a) => a.sponsor.key).toList();
    final sponsorsResponse = await DioFetchService().fetchSponsorsByIds(ids);
    final sponsorsModel =
        RootSponsorDataModel.fromJson(sponsorsResponse.data);

    if (sponsorsModel.data == null || sponsorsModel.data!.isEmpty) {
      return const _SponsorsResult(sponsors: [], exhibitors: []);
    }

    // 4. Enrich: attach resolved logo, category from junction, original order
    final enriched = sponsorsModel.data!
        .where((s) => s.id != null && orderMap.containsKey(s.id))
        .map((s) => _EnrichedSponsor(
              data: s,
              category: categoryMap[s.id!] ?? '',
              order: orderMap[s.id!] ?? 0,
            ))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    // 5. Split: exhibitors are category == 'exhibitor_only' (case-insensitive),
    //    rest are sponsors
    bool isExhibitor(_EnrichedSponsor s) =>
        s.category.toLowerCase() == 'exhibitor_only';
    final exhibitors = enriched.where(isExhibitor).toList();
    final sponsors = enriched.where((s) => !isExhibitor(s)).toList();

    return _SponsorsResult(sponsors: sponsors, exhibitors: exhibitors);
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
        child: FutureBuilder<_SponsorsResult>(
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
                  categoryOrder: _categoryOrder,
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
  final List<_EnrichedSponsor> sponsors;
  final List<String> categoryOrder;

  const _SponsorsTab(
      {required this.sponsors, required this.categoryOrder});

  @override
  Widget build(BuildContext context) {
    if (sponsors.isEmpty) {
      return const Center(child: Text('No sponsors available'));
    }

    // Group by category, preserving per-category order from the sorted list
    final grouped = <String, List<_EnrichedSponsor>>{};
    for (final s in sponsors) {
      grouped.putIfAbsent(s.category, () => []).add(s);
    }

    // Build section list: known categories first (in canonical order),
    // matched case-insensitively, then any remaining categories appended so
    // nothing is ever silently dropped.
    final canonicalLower = categoryOrder.map((c) => c.toLowerCase()).toList();
    final sections = <MapEntry<String, List<_EnrichedSponsor>>>[];
    final usedKeys = <String>{};

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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: sections.length,
      itemBuilder: (context, i) => _CategorySection(
        category: sections[i].key,
        sponsors: sections[i].value,
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<_EnrichedSponsor> sponsors;

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
  final List<_EnrichedSponsor> exhibitors;

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
  final _EnrichedSponsor exhibitor;

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
