import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants.dart';
import 'gallery_repository.dart';
import 'photo_viewer_screen.dart';

/// Event photo gallery — a masonry grid that keeps each photo's aspect ratio,
/// backed by the Event Image Service API (day/session filters, caption search,
/// cursor pagination). Tap any photo to view full-screen and download it.
class EventGalleryScreen extends StatefulWidget {
  const EventGalleryScreen({
    Key? key,
    this.eventId,
    this.eventName,
    this.pixEventId,
    this.initialDay,
  }) : super(key: key);

  /// The app's own (Directus) event id — kept for analytics/context only.
  final String? eventId;

  /// Event name, matched against the pix API's event titles to find the
  /// right gallery.
  final String? eventName;

  /// Resolved pix event id, supplied when opened straight from a photo
  /// notification — skips the name-matching lookup.
  final String? pixEventId;

  /// Day filter (`YYYY-MM-DD`) to preselect, e.g. when opened from a
  /// "Day 1 photos are now available" notification.
  final String? initialDay;

  @override
  State<EventGalleryScreen> createState() => _EventGalleryScreenState();
}

class _EventGalleryScreenState extends State<EventGalleryScreen> {
  String? _pixEventId;
  List<GalleryPhoto> _photos = [];
  String? _nextCursor;
  List<GalleryDay> _days = [];
  List<GallerySession> _sessions = [];

  String? _selectedDay;
  String? _selectedSessionId;
  String _search = '';

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();

  bool get _remote => GalleryRepository.isRemote;

  @override
  void initState() {
    super.initState();
    _pixEventId = widget.pixEventId;
    _selectedDay = widget.initialDay;
    if (_remote) {
      _bootstrap();
    } else {
      // No API credentials configured — bundled POC assets.
      _photos = GalleryRepository.assetPhotos();
      _loading = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      debugPrint('[Gallery] _bootstrap start: remote=$_remote, '
          'widget.pixEventId=${widget.pixEventId}, '
          'widget.eventName=${widget.eventName}, '
          'widget.eventId=${widget.eventId}, initialDay=${widget.initialDay}');
      _pixEventId ??=
          await GalleryRepository.resolveEventId(eventName: widget.eventName);
      final eventId = _pixEventId;
      if (eventId == null) {
        debugPrint('[Gallery] _bootstrap: resolveEventId returned null '
            '→ showing "no gallery available"');
        setState(() {
          _loading = false;
          _error = 'No photo gallery is available for this event yet.';
        });
        return;
      }
      debugPrint('[Gallery] _bootstrap: resolved pixEventId=$eventId');
      // Filters are nice-to-have — don't fail the whole gallery over them.
      final results = await Future.wait<dynamic>([
        GalleryRepository.fetchPhotos(
          eventId,
          day: _selectedDay,
          sessionId: _selectedSessionId,
          search: _search,
        ),
        GalleryRepository.fetchDays(eventId).catchError(
            (_) => <GalleryDay>[]),
        GalleryRepository.fetchSessions(eventId).catchError(
            (_) => <GallerySession>[]),
      ]);
      final page = results[0] as PhotosPage;
      final days = results[1] as List<GalleryDay>;
      final sessions = results[2] as List<GallerySession>;
      debugPrint('[Gallery] _bootstrap done: photos=${page.photos.length}, '
          'days=${days.length}, sessions=${sessions.length}, '
          'nextCursor=${page.nextCursor}');
      if (!mounted) return;
      setState(() {
        _photos = page.photos;
        _nextCursor = page.nextCursor;
        _days = days;
        _sessions = sessions;
        _loading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('[Gallery] _bootstrap error: $e\n$st');
      setState(() {
        _loading = false;
        _error = 'Could not load the gallery. Check your connection and retry.';
      });
    }
  }

  Future<void> _reload() async {
    final eventId = _pixEventId;
    if (eventId == null) return _bootstrap();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await GalleryRepository.fetchPhotos(
        eventId,
        day: _selectedDay,
        sessionId: _selectedSessionId,
        search: _search,
      );
      if (!mounted) return;
      setState(() {
        _photos = page.photos;
        _nextCursor = page.nextCursor;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load the gallery. Check your connection and retry.';
      });
    }
  }

  Future<void> _loadMore() async {
    final eventId = _pixEventId;
    final cursor = _nextCursor;
    if (eventId == null || cursor == null || _loadingMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final page = await GalleryRepository.fetchPhotos(
        eventId,
        day: _selectedDay,
        sessionId: _selectedSessionId,
        search: _search,
        cursor: cursor,
      );
      if (!mounted) return;
      setState(() {
        _photos = [..._photos, ...page.photos];
        _nextCursor = page.nextCursor;
        _loadingMore = false;
      });
    } catch (_) {
      // Silent: the next scroll attempt retries with the same cursor.
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _setDay(String? day) {
    if (day == _selectedDay) return;
    setState(() => _selectedDay = day);
    _reload();
  }

  void _setSession(String? sessionId) {
    if (sessionId == _selectedSessionId) return;
    setState(() => _selectedSessionId = sessionId);
    _reload();
  }

  void _submitSearch(String text) {
    final value = text.trim();
    if (value == _search) return;
    _search = value;
    _reload();
  }

  void _closeSearch() {
    setState(() => _searching = false);
    _searchController.clear();
    if (_search.isNotEmpty) {
      _search = '';
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldColor,
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search captions…',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onSubmitted: _submitSearch,
              )
            : const Text('Event Gallery'),
        backgroundColor: kConnectedBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_remote)
            IconButton(
              icon: Icon(_searching ? Icons.close : Icons.search),
              tooltip: _searching ? 'Close search' : 'Search captions',
              onPressed: () {
                if (_searching) {
                  _closeSearch();
                } else {
                  setState(() => _searching = true);
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_days.isNotEmpty) _dayChips(),
          if (_sessions.isNotEmpty) _sessionChips(),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_library_outlined,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _bootstrap,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_photos.isEmpty) {
      return _emptyState();
    }
    final grid = NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 600) {
          _loadMore();
        }
        return false;
      },
      child: MasonryGridView.count(
        // Always scrollable so pull-to-refresh works even on a short grid.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: _photos.length + (_nextCursor != null ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _photos.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _tile(context, i);
        },
      ),
    );
    return _remote ? RefreshIndicator(onRefresh: _reload, child: grid) : grid;
  }

  /// Friendly empty state shown when there are no photos to display. It
  /// distinguishes "your filters matched nothing" from "the gallery is filling
  /// up as the event goes on", and (when remote) stays pull-to-refresh capable
  /// so attendees can check for freshly-uploaded photos.
  Widget _emptyState() {
    final bool filtered = _search.isNotEmpty ||
        _selectedDay != null ||
        _selectedSessionId != null;

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filtered ? Icons.search_off : Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              filtered ? 'No photos match your filters' : 'No photos just yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              filtered
                  ? 'Try clearing your search or choosing a different day or session.'
                  : "Photos are added throughout the event, so check back soon — new moments will show up here as they're uploaded.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
            if (_remote && !filtered) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_downward,
                      size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (!_remote) return content;

    // Wrap in a scrollable so RefreshIndicator has something to respond to
    // even though there's no grid to scroll.
    return RefreshIndicator(
      onRefresh: _reload,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _dayChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All days'),
              selected: _selectedDay == null,
              onSelected: (_) => _setDay(null),
            ),
          ),
          for (final d in _days)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${_formatDay(d.day)} (${d.count})'),
                selected: _selectedDay == d.day,
                onSelected: (_) => _setDay(d.day),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sessionChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All sessions'),
              selected: _selectedSessionId == null,
              onSelected: (_) => _setSession(null),
            ),
          ),
          for (final s in _sessions)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(s.name),
                selected: _selectedSessionId == s.id,
                onSelected: (_) => _setSession(s.id),
              ),
            ),
        ],
      ),
    );
  }

  /// `2026-07-15` → `Jul 15`. Days come pre-computed in the event's timezone,
  /// so this is pure string formatting — no client timezone math.
  String _formatDay(String day) {
    final parts = day.split('-');
    if (parts.length != 3) return day;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = int.tryParse(parts[1]);
    final dayNum = int.tryParse(parts[2]);
    if (month == null || month < 1 || month > 12 || dayNum == null) return day;
    return '${months[month - 1]} $dayNum';
  }

  Widget _tile(BuildContext context, int i) {
    final photo = _photos[i];
    return GestureDetector(
      onTap: () => PersistentNavBarNavigator.pushNewScreen(
        context,
        screen: PhotoViewerScreen(photos: _photos, initialIndex: i),
        withNavBar: false,
        pageTransitionAnimation: PageTransitionAnimation.fade,
      ),
      child: Hero(
        tag: photo.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              _tileImage(photo),
              if (photo.caption != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                    child: Text(
                      photo.caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileImage(GalleryPhoto photo) {
    if (photo.isAsset) {
      // POC fallback: bundled asset at its natural aspect ratio.
      return Image.asset(
        photo.assetPath!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _brokenTile(),
      );
    }
    final thumb = photo.variantFor(const ['thumb', 'small']);
    if (thumb == null) return _brokenTile();
    // AspectRatio reserves the tile's final size before the bytes arrive, so
    // the masonry layout doesn't jump as images load.
    return AspectRatio(
      aspectRatio: photo.aspectRatio,
      child: CachedNetworkImage(
        imageUrl: thumb.url,
        // Signed URLs rotate hourly; the object itself is stable. Caching by
        // photo id + variant keeps the cache valid across URL re-signs.
        cacheKey: '${photo.id}-${thumb.label}',
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(color: Colors.white),
        ),
        errorWidget: (_, __, ___) => _brokenTile(),
      ),
    );
  }

  Widget _brokenTile() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: Image.asset(
          GalleryRepository.placeholder,
          width: 40,
          color: Colors.grey,
        ),
      ),
    );
  }
}
