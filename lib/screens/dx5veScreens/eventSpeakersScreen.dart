import 'dart:convert';

import 'package:dx5veevents/models/eventModel.dart';
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
  List<SpeakerAssociation> neoSpeakers = [];
  List<IndividualSpeaker> filteredSpeakers = []; // Store filtered speakers
  bool isFetching=true;
  @override
  void initState() {
    super.initState();

    fetchEventData();
  }


  Future fetchEventData()async{
    setState(() {
      isFetching=true;
    });
    final response= await DioFetchService().fetchEvents(eventID: widget.eventID);
    final Map<String, dynamic> responseData = response.data['data'];

    final List<dynamic> speakersData = responseData['speakers'];
    print("speaker dat is ${speakersData.length}");

    for (var speakerData in speakersData) {
      neoSpeakers.add(SpeakerAssociation.fromJson(speakerData));
    }




    for (var speaker in neoSpeakers) {
      fetchSpeakerById(speaker.speaker.key).then((value) {
        speakers.add(value!);

        setState(() {
          filteredSpeakers=speakers;
          print("spekers len $filteredSpeakers");
        });

      });
    }

    setState(() {
      //filteredSpeakers = speakers;
      isFetching = false;
    });



    return speakers;


  }

  Future<IndividualSpeaker?> fetchSpeakerById(int key) async {
    try {
      final response = await DioFetchService().fetchEventSpeakerByKey(speakerKey: key);
      final speakerssModel = SpeakersModel.fromJson(response.data);

      // Manually find the speaker to allow returning null.
      for (var speaker in speakerssModel.data) {
        print("speaker key is $key ");
      if(speaker.id==key){
        return speaker;
      }


      }

    } catch (e) {
      print("speaker eror is $e");
      return null;
    }
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

                  name: "${speaker.firstName} ${speaker.lastName}",


                  title: "${speaker.role} at ${speaker.company}",

                  bio: speaker!.bio! ?? "",

                  imageURL: "https://subscriptions.cioafrica.co/assets/${speaker!.photo!}",
                  linkedinurl: speaker.linkedinProfile ??"linkedin.com"), verticalSpace(height: 10)],);

              //   speakerWidget(context: context, name: speaker.name,
              //     title: speaker.title, bio: speaker.bio,imageURL: url
              // );
            },
          ),


        )
    );
  }
}