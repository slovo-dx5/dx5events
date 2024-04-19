import 'dart:convert';

import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../dioServices/dioFetchService.dart';
import '../../helpers/helper_widgets.dart';
import '../../models/image_model.dart';
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
  List<SpeakersModel> events = [];
  List<IndividualSpeaker> speakers = [];
  List<IndividualSpeaker> filteredSpeakers = []; // Store filtered speakers
  bool isFetching=true;
  @override
  void initState() {
    super.initState();

    fetchAllSpeakers(eventId: int.parse(widget.eventID));

  }


  Future<List<IndividualSpeaker>> fetchAllSpeakers({required int eventId}) async {
    final speakersResponse = await DioFetchService().fetchEventSpeakers();
    final eventResponse = await DioFetchService().fetchCISOTopics();

    // Assuming the data is already in the desired format after decoding
    final List<dynamic> speakerData = speakersResponse.data["data"];
    final List<dynamic> eventData = eventResponse.data["data"];


    var filteredProposals = eventData.where((proposal) => proposal['event_id'] == eventId).toList();

    for (var proposal in filteredProposals) {
      // Find the speaker details and convert them to IndividualSpeaker instances
      var speakerDetailMap = speakerData.firstWhere(
            (speaker) => speaker['id'] == proposal['speaker_id'],
        orElse: () => null,
      );


      if (speakerDetailMap != null) {
        // Convert the Map to an IndividualSpeaker instance using fromJson
        IndividualSpeaker speakerDetails = IndividualSpeaker.fromJson(speakerDetailMap);
        print("Speaker details are ${speakerDetails.firstName}");
        speakers.add(speakerDetails);
      }
    }

    //Update your state here as needed
    setState(() {
      filteredSpeakers = speakers;
      isFetching = false;
    });

    return speakers;
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
          ):const Column(
            children: [
              Text(
                "SPEAKERS",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,color: kToggleDark),
              ),
              Text(
                "AFRICA CISO SUMMIT",
                style: TextStyle(fontSize: 9, color: kTextColorGrey),
              )
            ],
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
              ? speakerShimmerWidget(context: context)
              : ListView.builder(

            padding:  EdgeInsets.all(8),
            itemCount: filteredSpeakers.length,
            itemBuilder: (context, index) {
              final IndividualSpeaker speaker = filteredSpeakers[index];

              return Column(children: [speakerWidget(context: context,

                  name: "${speaker.firstName!} ${speaker.lastName}",


                  title: "${speaker.role!} at ${speaker.company}",

                  bio: speaker!.bio! ?? "",

                  imageURL: "https://subscriptions.cioafrica.co/assets/${speaker!.photo!}",
                  linkedinurl: speaker.linkedinProfile!), verticalSpace(height: 10)],);

              //   speakerWidget(context: context, name: speaker.name,
              //     title: speaker.title, bio: speaker.bio,imageURL: url
              // );
            },
          ),


        )
    );
  }
}