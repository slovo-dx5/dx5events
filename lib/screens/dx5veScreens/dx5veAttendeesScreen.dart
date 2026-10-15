import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../constants.dart';
import '../../helpers/helper_widgets.dart';
import '../../models/eventAttendeesModel.dart';
import '../../providers.dart';
import '../../repositories/attendees_repository.dart';
import '../../services/activity_logger.dart';
import '../../widgets/app_sponsor.dart';
import '../../widgets/search_debouncer.dart';

class AttendeesScreen extends StatefulWidget {
  final String eventID;

  const AttendeesScreen({super.key, required this.eventID});

  @override
  State<AttendeesScreen> createState() => _AttendeesScreenState();
}

class _AttendeesScreenState extends State<AttendeesScreen> {
  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Pagination variables
  static const int _pageSize = 20;
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  // Search state
  bool _isSearching = false;
  String _searchQuery = '';

  // Attendees data
  List<EventAttendeeModel> _attendeesList = [];
  final _searchDebouncer = SearchDebouncer();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_scrollListener);
    _fetchAttendees();
    ActivityLogger.instance.log(
      action: ActivityAction.viewAttendees,
      eventId: widget.eventID,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    _refreshController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchAttendees();
    }
  }

  Future<void> _fetchAttendees({bool forceRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final page = await AttendeesRepository.instance.getPage(
        eventID: widget.eventID,
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchQuery,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;
      setState(() {
        if (_currentPage == 1) {
          _attendeesList = page.attendees;
        } else {
          _attendeesList.addAll(page.attendees);
        }
        _hasMore = page.hasMore;
        _currentPage++;
      });
    } catch (e) {
      debugPrint('Error fetching attendees: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (_refreshController.isRefresh) {
        _refreshController.refreshCompleted();
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
    });
    await AttendeesRepository.instance.invalidateEvent(widget.eventID);
    await _fetchAttendees(forceRefresh: true);
  }

  void _onSearchChanged(String query) {
    _searchDebouncer.run(() {
      setState(() {
        _searchQuery = query;
        _currentPage = 1;
        _hasMore = true;
      });
      _fetchAttendees();
    });
  }

  /// Attendees per sponsor card. The list runs in blocks of this many
  /// attendees followed by one sponsor card.
  static const int _sponsorEvery = AppSponsor.attendeeInterval;
  static const bool _showSponsor = AppSponsor.enabled;

  int _calculateTotalItemCount() {
    // A sponsor card after every full block of attendees.
    final sponsorCount =
        _showSponsor ? _attendeesList.length ~/ _sponsorEvery : 0;
    // Total = attendees + sponsors + (loading indicator if hasMore)
    return _attendeesList.length + sponsorCount + (_hasMore ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by Name, Role or Company',
            hintStyle: TextStyle(fontSize: 12),
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        )
            : const Column(
          children: [
            Text(
              "ATTENDEES",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                  _refreshData();
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: (_attendeesList.isEmpty &&  _isLoading)
            ? const Center(
          child: SpinKitCircle(
            color: kConnectedBlue,
          ),
        )
            : SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          header: const WaterDropHeader(
            waterDropColor: kConnectedBlue,
          ),
          onRefresh: _refreshData,
          child: ListView.builder(
            controller: _scrollController,
            itemCount:  _calculateTotalItemCount(),
            itemBuilder: (context, index) {
              // Rows come in blocks of _sponsorEvery attendees + 1 sponsor.
              final block = _showSponsor ? _sponsorEvery + 1 : 1 << 30;
              if (_showSponsor && index % block == _sponsorEvery) {
                return const AppSponsorAttendeeCard();
              }
              final actualAttendeeIndex =
                  (index ~/ block) * _sponsorEvery + index % block;

              // Show loading indicator at the end if more items are available
              if (actualAttendeeIndex >= _attendeesList.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              {
                final user = _attendeesList[actualAttendeeIndex];
                return profileProvider.userID == user.attendeeId
                    ? meWidget(
                  assetName: "assetName",
                  context: context,
                  firstName: user.firstName,
                  lastName: user.lastName,
                  role: user.role,
                  company: user.company,
                  interests: [],
                  profileid: user.profilePhoto ?? "",
                  userID: user.id,
                )
                    : attendeeWidget(
                  assetName: "assetName",
                  context: context,
                  firstName: user.firstName,
                  lastName: user.lastName,
                  attendeeEmail: user.workEmail,
                  role: user.role,
                  company: user.company,
                  interests: [],
                  profileid: user.profilePhoto ?? "",
                  userID: user.attendeeId, requestedByphone: profileProvider.phone,
                  meetingWithPhone: user.phone??"", hasDownloadedApp: user.hasDownloadedApp, currentUserName:"${profileProvider.firstName } ${profileProvider.lastName}",
                );
              }
            },
          ),
        ),
      ),
    );
  }
}