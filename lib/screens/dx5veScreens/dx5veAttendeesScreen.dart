import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../constants.dart';
import '../../dioServices/dioFetchService.dart';
import '../../helpers/helper_widgets.dart';
import '../../models/eventAttendeesModel.dart';
import '../../providers.dart';
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

  // Dio setup
  late final Dio dio;
  late final DioCacheManager dioCacheManager;

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

    // Initialize Dio with cache
    dio = Dio();

    dioCacheManager = DioCacheManager(CacheConfig(
      defaultMaxAge: const Duration(days: 1),
      defaultMaxStale: const Duration(days: 7),
    ));
    dio.interceptors.add(dioCacheManager.interceptor);

    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);

    // Initial data load
    _fetchAttendees();
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

  Future<void> _fetchAttendees() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Construct the API endpoint with pagination parameters
      // final response = widget.isCustomerEvent == false
      //     ?
      final response =  await DioFetchService().
      fetchCIOAttendees(
        eventID: widget.eventID,
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchQuery,
      );
      //     : await DioFetchService().fetchCustomerEventsAttendees(
      //   eventID: widget.eventID,
      //   page: _currentPage,
      //   pageSize: _pageSize,
      //   searchQuery: _searchQuery,
      // );

      if (response.statusCode == 200) {
        final rawData = response.data['data'];
        final List<dynamic> filteredData = rawData
            .where((item) => item['status'] == "approved")
            .toList();


          List<EventAttendeeModel> fetchedAttendees = filteredData
              .map((userJson) => EventAttendeeModel.fromJson(userJson))
              .toList();

          setState(() {
            if (_currentPage == 1) {
              _attendeesList = fetchedAttendees;
            } else {
              _attendeesList.addAll(fetchedAttendees);
            }
            _hasMore = fetchedAttendees.length >= _pageSize;
            _currentPage++;
          });


      }
    } catch (e) {
      debugPrint('Error fetching attendees: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });

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
    await dioCacheManager.clearAll();
    await _fetchAttendees();
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

  int _calculateTotalItemCount() {
    // Calculate how many sponsor widgets to insert (after every 5 attendees)
    int sponsorCount = _attendeesList.length ~/ 5;
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
              // Calculate sponsor positions (after every 5 attendees)
              // Position 5, 11, 17, 23... (formula: 5 + (n * 6))
              int sponsorInsertions = (index + 1) ~/ 6;
              int actualAttendeeIndex = index - sponsorInsertions;

              // Check if current position should show sponsor
              bool isSponsorPosition = (index + 1) % 6 == 0 && index < _attendeesList.length + sponsorInsertions;

              if (isSponsorPosition) {
                return sponsorWidget(
                  context: context,
                  sponsorName: "MBCom",
                  sponsorLogoPath: "assets/images/sponsors/mbcom_profile.png",
                );
              }

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
                return profileProvider.userID == user.id
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
                  meetingWithPhone: user.phone, hasDownloadedApp: user.hasDownloadedApp, currentUserName:"${profileProvider.firstName } ${profileProvider.lastName}",
                );
              }
            },
          ),
        ),
      ),
    );
  }
}