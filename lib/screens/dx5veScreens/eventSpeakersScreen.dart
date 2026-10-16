import 'package:dx5veevents/models/eventModel.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../constants.dart';
import '../../helpers/speaker_helper.dart';
import '../../models/agendaModel.dart';
import '../../models/speakersModel.dart';
import '../../repositories/agenda_repository.dart';
import '../../repositories/event_repository.dart';
import '../../services/activity_logger.dart';
import '../../widgets/speakerWidget.dart';

class EventSpeakersScreen extends StatefulWidget {
  String eventID;
   EventSpeakersScreen({super.key, required this.eventID});

  @override
  State<EventSpeakersScreen> createState() => _EventSpeakersScreenState();
}

class _EventSpeakersScreenState extends State<EventSpeakersScreen> {
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final RefreshController _refreshController = RefreshController();
  List<IndividualSpeaker> speakers = [];
  List<IndividualSpeaker> filteredSpeakers = [];
  List<AgendaDay> _agendaDays = [];
  bool isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
    ActivityLogger.instance.log(
      action: ActivityAction.viewSpeakers,
      eventId: widget.eventID,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadAll({bool forceRefresh = false}) async {
    setState(() => isFetching = true);

    try {
      final eventData = await EventRepository.instance.getEventData(
        eventID: widget.eventID,
        forceRefresh: forceRefresh,
      );
      final List<dynamic> speakersData = eventData['speakers'] ?? [];

      if (speakersData.isNotEmpty) {
        final associations = speakersData
            .map((s) => SpeakerAssociation.fromJson(s))
            .toList();

        final enriched = await getSpeakers(
          associations,
          forceRefresh: forceRefresh,
        );

        if (!mounted) return;
        setState(() {
          speakers = enriched.map((e) => e.speaker).toList();
          filteredSpeakers = _applySearch(_searchController.text);
        });
      } else if (mounted) {
        setState(() {
          speakers = [];
          filteredSpeakers = [];
        });
      }

      // Agenda is used only for per-speaker topics lookup.
      // If the user already visited the agenda screen, this is a cache hit.
      final agendaModel = await AgendaRepository.instance.getAgenda(
        eventID: widget.eventID,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _agendaDays = agendaModel.days;
      });
    } catch (e) {
      debugPrint('Error loading speakers screen: $e');
    } finally {
      if (mounted) setState(() => isFetching = false);
    }
  }

  List<IndividualSpeaker> _applySearch(String query) {
    if (query.isEmpty) return List.of(speakers);
    final q = query.toLowerCase();
    return speakers.where((data) {
      return data.firstName.toLowerCase().contains(q) ||
          data.role.toLowerCase().contains(q);
    }).toList();
  }

  // Returns every session (with date & time) in the agenda where this speaker appears.
  List<SpeakerSession> _getTopicsForSpeaker(int speakerId) {
    final sessions = <SpeakerSession>[];
    for (final day in _agendaDays) {
      for (final session in day.sessions) {
        if (session.speakers == null) continue;
        final inSession = session.speakers!.any(
          (a) => a.speaker.key == speakerId,
        );
        if (inSession && session.title != null) {
          final title = session.title as String;
          final alreadyAdded = sessions.any((s) => s.title == title);
          if (!alreadyAdded) {
            sessions.add(SpeakerSession(
              title: title,
              date: day.date as DateTime,
              startTime: session.startTime?.toString() ?? '',
              endTime: session.endTime?.toString() ?? '',
            ));
          }
        }
      }
    }
    return sessions;
  }

  void filterData(String query) {
    setState(() {
      filteredSpeakers = _applySearch(query);
    });
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(backgroundColor: kScaffoldColor,
          automaticallyImplyLeading: true,
          centerTitle: true,
          title:  isSearching
              ? TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by Name, Role or Company',
              hintStyle: TextStyle(fontSize: 12),
              border: InputBorder.none,
            ),
            onChanged: (query) {
              filterData(query);

            },
          ):Text(
            "SPEAKERS",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,color: kToggleDark),
          ),
          actions: [ IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search,color: kTextColorBlack,),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  _searchController.clear();
                  filterData('');

                }
              });
            },
          ),],
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: isFetching && speakers.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SmartRefresher(
                  controller: _refreshController,
                  enablePullDown: true,
                  header: const WaterDropHeader(waterDropColor: kCIOPink),
                  onRefresh: () async {
                    await _loadAll(forceRefresh: true);
                    _refreshController.refreshCompleted();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredSpeakers.length,
                    itemBuilder: (context, index) {
                      final IndividualSpeaker speaker =
                          filteredSpeakers[index];
                      return Column(
                        children: [
                          speakerWidget(
                            context: context,
                            name: "${speaker.firstName} ${speaker.lastName}",
                            title:
                                "${speaker.role} at ${speaker.company}",
                            bio: speaker.bio ?? "",
                            imageURL: speaker.photo,
                            linkedinurl:
                                speaker.linkedinProfile ?? "linkedin.com",
                            sessions: _getTopicsForSpeaker(speaker.id),
                          ),
                          const Divider(color: Colors.green),
                          verticalSpace(height: 10),
                        ],
                      );
                    },
                  ),
                ),
        ));
  }
}