
import 'dart:convert';

import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';

import '../../dioServices/dioFetchService.dart';
import '../../models/eventModel.dart';
import '../../models/sponsor_data_model.dart';
import '../../widgets/cool_background.dart';
import '../../widgets/sponsor_widget.dart';
class CISOSponsorsScreen extends StatefulWidget {
  String eventID;
   CISOSponsorsScreen({required this.eventID,super.key});

  @override
  State<CISOSponsorsScreen> createState() => _CISOSponsorsScreenState();
}

class _CISOSponsorsScreenState extends State<CISOSponsorsScreen> {

  List<SponsorAssociation> neosponsors = [];
  Map <int, List<dynamic>> sponsorMap={};
  bool isFetching=false;
  int index = 0;

  @override
  void initState() {
    fetchEventData();
super.initState();
  }





  Future fetchSponsorById({required int key}) async {
    try {
      final response = await DioFetchService().fetchEventSponsors();
      final sponsorsModel = RootSponsorDataModel.fromJson(response.data);

      // Manually find the speaker to allow returning null.
      for (var sponsor in sponsorsModel.data!) {
        if (sponsor.id == key) {
          return sponsor;
        }
      }
      return null; // Explicitly return null if no speaker matches the key.
    } catch (e) {
      print(e);
      return null;
    }
  }

  fetchEventData()async{
    setState(() {
      isFetching=true;
    });
    final response= await DioFetchService().fetchEvents(eventID: widget.eventID);
    final Map<String, dynamic> responseData = response.data['data'];

    final List<dynamic> sponsorsData = responseData['sponsors'];



    for (var sponsorData in sponsorsData) {
      neosponsors.add(SponsorAssociation.fromJson(sponsorData));
    }

    for (var sponsor in neosponsors) {
      try {
        var receivedSponsor = await fetchSponsorById(key: sponsor.sponsor.key);
        sponsorMap[index] = [sponsor.category, receivedSponsor];
        index++; // Increment index for the next sponsor
      } catch (e) {
        print("fetch error is $e");
      }
    }
    setState(() {
      isFetching=false;
    });
    print("SPonsor data is ${sponsorMap.length}");

  }


  @override
  Widget build(BuildContext context) {
    return  SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white.withOpacity(0.7),
        body: Stack(
        children: [
         
          Container(height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                Container(height:55,width:MediaQuery.of(context).size.width,child: Row(children: [
                  IconButton(onPressed: (){Navigator.of(context).pop();}, icon: Icon(Icons.chevron_left,color: Colors.black54,size: 35,)),
                  Spacer(),
                  const Text("MEET OUR SPONSORS", style: TextStyle(fontSize:17,fontWeight: FontWeight.w600 ,color:  Colors.black54),)
                  ,Spacer(),

                ],),),
                const Divider(color: Colors.black,),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:Column(
                      children: [

                        Flexible(
                          child: Visibility(
                            visible:isFetching==false,
                            replacement: CircularProgressIndicator(),

                            child: ListView.builder(

                              padding:  const EdgeInsets.all(8),
                              itemCount: sponsorMap.length,
                              itemBuilder: (context, index) {
                                final entry = sponsorMap.entries.elementAt(index);
                                final category = entry.key;
                                final sponsorrr = entry.value;


                                if(sponsorMap==null){return const Text("Sponsors will appear here");}else{
                                  return Column(children: [sponsorWidget(context: context, sponsorAsset:"https://subscriptions.cioafrica.co/assets/${sponsorrr[1].transparent_logo??sponsorrr[1].logo}",
                                    //degree: "${sponsors[index].degree!}°",
                                    degree: "${sponsorrr[0]}°",
                                    sponsorName:sponsorrr[1].sponsorName!,
                                    sponsorBio:sponsorrr[1].about!, sponsorURL: sponsorrr[1].websites!.first.link!,

                                  ),
                                    Divider(),
                                    verticalSpace(height: 10),],);
                                }

                                //   speakerWidget(context: context, name: speaker.name,
                                //     title: speaker.title, bio: speaker.bio,imageURL: url
                                // );
                              },
                            ),
                          ),
                        ),




                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),),
    );
  }
}
