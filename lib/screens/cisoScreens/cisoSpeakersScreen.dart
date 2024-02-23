import 'dart:convert';

import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../dioServices/dioFetchService.dart';
import '../../helpers/helper_widgets.dart';
import '../../models/image_model.dart';
import '../../models/speakersModel.dart';
import '../../widgets/speakerWidget.dart';

class CisoSpeakersScreen extends StatefulWidget {
  const CisoSpeakersScreen({super.key});

  @override
  State<CisoSpeakersScreen> createState() => _CisoSpeakersScreenState();
}

class _CisoSpeakersScreenState extends State<CisoSpeakersScreen> {
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

    fetchAllSpeakers();

  }
  Future<List<IndividualSpeaker>> fetchAllSpeakers() async {
    final response = await DioFetchService().fetchCISOSpeakers();


    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(json.encode(response.data["data"]));
      final List<IndividualSpeaker> speakersList = data.map((eventData) => IndividualSpeaker.fromJson(eventData)).toList();
      setState(() {
        speakers =speakersList;
        filteredSpeakers = speakers;
        isFetching=false;
      });
      return speakersList;
    } else {
      throw Exception('Failed to load events');
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
              : GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisSpacing: 0,
              crossAxisSpacing:4,
              crossAxisCount: 2,
              childAspectRatio: 1.6/2,
            ),
            padding:  EdgeInsets.all(8),
            itemCount: filteredSpeakers.length,
            itemBuilder: (context, index) {
              final IndividualSpeaker speaker = filteredSpeakers[index];

              return speakerWidget(context: context, name: "${speaker.firstName!} ${speaker.lastName}", title: "${speaker.role!} @ ${speaker.company}",
                  bio: speaker!.bio!,imageURL: "https://subscriptions.cioafrica.co/assets/${speaker!.photo!}", linkedinurl: speaker.linkedinProfile!);

              //   speakerWidget(context: context, name: speaker.name,
              //     title: speaker.title, bio: speaker.bio,imageURL: url
              // );
            },
          ),


        )
    );
  }
}
