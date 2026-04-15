import 'package:dx5veevents/models/eventModel.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../dioServices/dioFetchService.dart';
import '../../helpers/helper_widgets.dart';
import '../../helpers/speaker_helper.dart';
import '../../models/agendaModel.dart';
import '../../models/speakersModel.dart';
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
  //List<Map<String, dynamic>> filteredData = [];
  List<IndividualSpeaker> speakers = [];
  List<IndividualSpeaker> filteredSpeakers = [];
  List<AgendaDay> _agendaDays = [];
  bool isFetching = true;

  @override
  void initState() {
    super.initState();
    fetchEventData();
    _fetchAgendaDays();
  }


  Future<void> fetchEventData() async {
    setState(() => isFetching = true);

    try {
      final response =
          await DioFetchService().fetchEvents(eventID: widget.eventID);
      final Map<String, dynamic> responseData = response.data['data'];
      final List<dynamic> speakersData = responseData['speakers'] ?? [];

      if (speakersData.isNotEmpty) {
        final associations = speakersData
            .map((s) => SpeakerAssociation.fromJson(s))
            .toList();

        // Bulk-fetch and preserve Directus order in one call
        final enriched = await getSpeakers(associations);

        if (mounted) {
          setState(() {
            speakers = enriched.map((e) => e.speaker).toList();
            filteredSpeakers = speakers;
            isFetching = false;
          });
        }
      } else {
        if (mounted) setState(() => isFetching = false);
      }
    } catch (e) {
      debugPrint('Error fetching speakers: $e');
      if (mounted) setState(() => isFetching = false);
    }
  }



  Future<void> _fetchAgendaDays() async {
    try {
      final response = await DioFetchService().fetchdx5veAgenda(eventID: widget.eventID);
      final agendaModel = AgendaModel.fromJson(response.data);
      if (mounted) {
        setState(() {
          _agendaDays = agendaModel.days;
        });
      }
    } catch (e) {
      debugPrint('Error fetching agenda for speaker topics: $e');
    }
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
      if (query.isEmpty) {
        filteredSpeakers = speakers;
      } else {
        filteredSpeakers = speakers.where((data) {
          final fullName = '${data.firstName}';
          return fullName.toLowerCase().contains(query.toLowerCase()) ||

              data.role.toLowerCase().contains(query.toLowerCase())
          ;
        }).toList();
      }
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
        body:
        Padding(padding: EdgeInsets.only(top: 8),
          child: isFetching
              ? const Center(child: CircularProgressIndicator(),)
              : ListView.builder(

            padding:  EdgeInsets.all(8),
            itemCount: filteredSpeakers.length,
            itemBuilder: (context, index) {
              final IndividualSpeaker speaker = filteredSpeakers[index];

              return Column(children: [
                speakerWidget(context: context,

                  name: "${speaker.firstName} ${speaker.lastName}",


                  title: "${speaker.role} at ${speaker.company}",

                  bio: speaker!.bio! ?? "",

                  imageURL: speaker.photo,
                  linkedinurl: speaker.linkedinProfile ?? "linkedin.com",
                  sessions: _getTopicsForSpeaker(speaker.id)),
                Divider(color: Colors.green,),
                verticalSpace(height: 10)],);

              //   speakerWidget(context: context, name: speaker.name,
              //     title: speaker.title, bio: speaker.bio,imageURL: url
              // );
            },
          ),


        )
    );
  }
}