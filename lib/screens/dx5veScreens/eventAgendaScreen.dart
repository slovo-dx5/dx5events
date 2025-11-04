import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';


import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../dioServices/base_url.dart';
import '../../dioServices/dioFetchService.dart';
import '../../helpers/analytics_helper.dart';
import '../../helpers/helper_functions.dart';
import '../../models/agendaModel.dart';
import '../../models/speakersModel.dart';
import '../../providers.dart';
import '../../widgets/agendaWidget.dart';
import '../../widgets/appbarWidget.dart';
import 'eventFullAgenda.dart';

class EventAgendaScreen extends StatefulWidget {
  String eventID;
  String eventName;
  int eventDay;
  int eventMonth;
  int eventYear;

  String eventLocation;
  String eventDayOfWeek;


  EventAgendaScreen(
      {super.key,
      required this.eventID,
      required this.eventName,

      required this.eventDay,
        required this.eventDayOfWeek,
      required this.eventMonth,
        required this.eventLocation,
      required this.eventYear});

  @override
  State<EventAgendaScreen> createState() => _EventAgendaScreenState();
}

class _EventAgendaScreenState extends State<EventAgendaScreen> {
  Map<DateTime, AgendaDay> _dayToAgendaMap = {};
  DateTime? _selectedDate;
  final RefreshController _refreshController = RefreshController();
  DioCacheManager dioCacheManager = DioCacheManager(CacheConfig());

  List<AgendaDay> agendaDays = [];
  bool isFetching = true;
  int attendeeID = 0;
  String? _selectedStage;
  List<String> _availableStages = [];

  @override
  void initState() {
    super.initState();
    getAttendeeID();
    setState(() {
      _selectedDate = DateTime(widget.eventYear, widget.eventMonth, widget.eventDay);
    });
    _loadSessions();
  }

  Future<void> getAttendeeID() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? attendeeIDD = prefs.getInt(kUserID);
      setState(() {
        attendeeID = attendeeIDD!;
      });
    } catch (e) {
      debugPrint('Error getting attendee ID: $e');
    }
  }



  Future<void> _loadSessions() async {
    setState(() {
      isFetching = true;
    });
    await fetchSessions();
    setState(() {
      _extractAvailableStages();
      _dayToAgendaMap = { for (var item in agendaDays) (item).date : item };
      isFetching = false;
    });
    debugPrint('Loaded ${agendaDays.length} days with ${_dayToAgendaMap.length} mapped days');
  }

  void _extractAvailableStages() {
    Set<String> stages = {};
    for (var day in agendaDays) {
      for (var session in day.sessions) {
        if (session.stage != null && session.stage.toString().trim().isNotEmpty) {
          stages.add(session.stage.toString());
        }
      }
    }
    _availableStages = stages.toList()..sort();
  }



  Future<List<Session>> fetchSessions() async {
    try {
      final response = await DioFetchService().fetchdx5veAgenda(eventID: widget.eventID);
      final agendaModel = AgendaModel.fromJson(response.data);

      setState(() {
        agendaDays = agendaModel.days;
      });

      return agendaModel.days.expand((day) => day.sessions).toList();
    } catch (e) {
      debugPrint("Error fetching sessions: $e");
      return [];
    }
  }

  Future<IndividualSpeaker?> fetchSpeakerById(int key) async {
    try {
      final response = await DioFetchService().fetchEventSpeakerByKey(speakerKey: key);
      final speakersModel = SpeakersModel.fromJson(response.data);

      if (speakersModel.data.isNotEmpty) {
        return speakersModel.data.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching speaker by ID: $e');
      return null;
    }
  }

  List<Session> _getFilteredSessions(List<Session> sessions) {
    if (_selectedStage == null) {
      return sessions; // Show all sessions when no filter is selected
    }

    // Show only sessions matching the selected stage OR sessions with null stage
    return sessions.where((session) {
      return session.stage == null ||
             session.stage.toString() == _selectedStage;
    }).toList();
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'June',
                    'July', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _formatTime(String time) {
    // Convert 24-hour time to display format (HH:mm)
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }
    } catch (e) {
      return time;
    }
    return time;
  }

  bool _isSessionNow(String startTime, String endTime, DateTime sessionDate) {
    try {
      final now = DateTime.now();

      // Check if the session is on today's date
      final isToday = now.year == sessionDate.year &&
                      now.month == sessionDate.month &&
                      now.day == sessionDate.day;

      if (!isToday) {
        return false;
      }

      final startParts = startTime.split(':');
      final endParts = endTime.split(':');

      final startDateTime = DateTime(
        sessionDate.year,
        sessionDate.month,
        sessionDate.day,
        int.parse(startParts[0]),
        int.parse(startParts[1].substring(0, 2))
      );

      final endDateTime = DateTime(
        sessionDate.year,
        sessionDate.month,
        sessionDate.day,
        int.parse(endParts[0]),
        int.parse(endParts[1].substring(0, 2))
      );

      return now.isAfter(startDateTime) && now.isBefore(endDateTime);
    } catch (e) {
      return false;
    }
  }

  Color _getSessionColor(int index) {
    final colors = [
      Color(0xFFFF9800), // Orange
      Color(0xFF2196F3), // Blue
      Color(0xFF4CAF50), // Green
      Color(0xFFF44336), // Red
      Color(0xFF9C27B0), // Purple
      Color(0xFF00BCD4), // Cyan
      Color(0xFFFF5722), // Deep Orange
      Color(0xFF3F51B5), // Indigo
    ];
    return colors[index % colors.length];
  }

  Widget _buildTimelineSessionItem({
    required BuildContext context,
    required Session session,
    required ProfileProvider profileProvider,
    required bool isNow,
    required bool showTimeline,
    required int index,
  }) {
    final sessionColor = _getSessionColor(index);

    if (isNow) {
      debugPrint('NOW Session: ${session.title}, Stage: ${session.stage}, Speakers: ${session.speakers?.length ?? 0}');
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionTime(session, isNow),
          _buildTimelineDot(
            isNow: isNow,
            sessionColor: sessionColor,
            showTimeline: showTimeline,
          ),

          // Session card
          Expanded(
            child: GestureDetector(
              // onTap: () {
              //   // Fetch speaker details if needed
              //   final futures = session.speakers != null && session.speakers!.isNotEmpty
              //       ? session.speakers!.map((speaker) => fetchSpeakerById(speaker.speaker.key)).toList()
              //       : <Future<IndividualSpeaker?>>[];
              //
              //   PersistentNavBarNavigator.pushNewScreen(
              //     context,
              //     screen: FullAgendaScreen(
              //       title: session.title,
              //       day: widget.eventDay,
              //       startTime: session.startTime,
              //       endTime: session.endTime ?? '',
              //       isFromSession: false,
              //       type: session.sessionType ?? '',
              //       userID: profileProvider.userID!,
              //       description: session.summary,
              //       speakers: session.speakers ?? [],
              //       breakOuts: session.breakoutSessions,
              //       eventLocation: widget.eventLocation,
              //       eventDay: widget.eventDay,
              //       eventMonth: widget.eventMonth,
              //       eventYear: widget.eventYear,
              //       futures: futures,
              //       date: widget.eventDayOfWeek,
              //       sessionId: session.sessionId,
              //       sessionDate: _dayToAgendaMap[_selectedDate]!.date!,
              //       eventID: widget.eventID,
              //     ),
              //     withNavBar: false,
              //     pageTransitionAnimation: PageTransitionAnimation.slideRight,
              //   );
              // },
              child: Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isNow ? const Color(0xFFE3F2FD) : sessionColor.withOpacity(0.08),
                      border: isNow
                          ? Border.all(color: Colors.blue.withOpacity(0.3), width: 1)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          color: isNow ? Colors.blue : sessionColor,
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                    // Session title and NOW badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.title ?? 'No Title',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (isNow)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'NOW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Stage/Location
                    if (session.stage != null)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              session.stage.toString(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Speakers
                    if (session.speakers != null && session.speakers!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Column(
                          children: session.speakers!.take(2).map((speakerAssignment) {
                            return FutureBuilder<IndividualSpeaker?>(
                              future: fetchSpeakerById(speakerAssignment.speaker.key),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return _buildSpeakerItem(snapshot.data!, isNow);
                                }
                                return SizedBox.shrink();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

        ),
     ] ),
    );
  }

  Widget _buildTimelineDot({
    required bool isNow,
    required Color sessionColor,
    required bool showTimeline,
  }) {
    return SizedBox(
      width: 30,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNow ? Colors.blue : sessionColor.withOpacity(0.3),
              border: Border.all(
                color: isNow ? Colors.blue : sessionColor,
                width: isNow ? 3 : 2,
              ),
            ),
          ),
          if (showTimeline)
            Expanded(
              child: Container(
                width: 2,
                color: isNow ? Colors.blue : Colors.grey[300],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionTime(Session session, bool isNow) {
    return SizedBox(
      width: 70,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatTime(session.startTime),
            style: TextStyle(
              color: isNow ? Colors.blue : Colors.grey[700],
              fontSize: 16,
              fontWeight: isNow ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(session.endTime ?? ''),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerItem(IndividualSpeaker speaker, bool isNow) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: speaker.photo != null
                ? CachedNetworkImageProvider(
                    '${BaseURL.Baseurl}/assets/${speaker.photo}',
                  )
                : null,
            child: speaker.photo == null ? const Icon(Icons.person, size: 20) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${speaker.firstName ?? ''} ${speaker.lastName ?? ''}'.trim(),
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTab(AgendaDay agendaDay) {
    final date = agendaDay.date as DateTime;
    final isSelected = isSameDay(_selectedDate, date);
    final monthName = _getMonthName(date.month);
    final day = date.day;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = date;
          });
        },
        child: Column(
          children: [
            Text(
              '$monthName $day',
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey[600],
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 8),
            if (isSelected)
              Container(
                height: 3,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showStageFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by Stage',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 10),
              ListTile(
                leading: Icon(
                  _selectedStage == null ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: kCIOPink,
                ),
                title: Text('All Stages'),
                onTap: () {
                  setState(() {
                    _selectedStage = null;
                  });
                  Navigator.pop(context);
                },
              ),
              Divider(),
              ..._availableStages.map((stage) => ListTile(
                leading: Icon(
                  _selectedStage == stage ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: kCIOPink,
                ),
                title: Text(stage),
                onTap: () {
                  setState(() {
                    _selectedStage = stage;
                  });
                  Navigator.pop(context);
                },
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.eventName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: _selectedStage != null ? Colors.blue : Colors.black,
              ),
              tooltip: 'Filter by stage',
              onPressed: _showStageFilterBottomSheet,
            ),
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: agendaDays.map((agendaDay) => _buildDateTab(agendaDay)).toList(),
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey[300]),
            Visibility(
              visible: isFetching == false,
              replacement: const CircularProgressIndicator(),
              child: Expanded(
                child: SmartRefresher(
                  controller: _refreshController,
                  enablePullDown: true,
                  header: const WaterDropHeader(
                    waterDropColor: kCIOPink,
                  ),
                  onRefresh: () async {
                   // await dioCacheManager.clearAll();
                    //await fetchDx5veAgendaHere();

                    setState(() {
                      _refreshController.refreshCompleted();
                    });
                  },
                  onLoading: () async {
                    await Future.delayed(Duration(milliseconds: 1000));
                    setState(() {
                      _refreshController.loadComplete();
                    });
                  },
                  child: _dayToAgendaMap.containsKey(_selectedDate)
                      ? Builder(
                          builder: (context) {
                            final filteredSessions = _getFilteredSessions(
                                _dayToAgendaMap[_selectedDate]!.sessions);

                            if (filteredSessions.isEmpty) {
                              return Center(
                                child: Text('No sessions available for the selected stage'),
                              );
                            }

                            return ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: filteredSessions.length,
                              itemBuilder: (context, index) {
                                final session = filteredSessions[index];
                                final sessionDate = _dayToAgendaMap[_selectedDate]!.date!;
                                final isNow = _isSessionNow(session.startTime, session.endTime ?? '', sessionDate);
                                final showTimeline = index < filteredSessions.length - 1;

                                debugPrint('Session $index: title="${session.title}", isNow=$isNow, start=${session.startTime}, end=${session.endTime}, date=$sessionDate');

                                return _buildTimelineSessionItem(
                                  context: context,
                                  session: session,
                                  profileProvider: profileProvider,
                                  isNow: isNow,
                                  showTimeline: showTimeline,
                                  index: index,
                                );
                          },
                            );
                          },
                        )
                      : Center(
                          child: Text('No sessions available for this day'),
                        ),
                ),
              ),
            )
          ],
        ));
  }
}
