
import 'dart:convert';

import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';

import '../../dioServices/dioFetchService.dart';
import '../../models/sponsor_data_model.dart';
import '../../widgets/cool_background.dart';
import '../../widgets/sponsor_widget.dart';
class CISOSponsorsScreen extends StatefulWidget {
  const CISOSponsorsScreen({super.key});

  @override
  State<CISOSponsorsScreen> createState() => _CISOSponsorsScreenState();
}

class _CISOSponsorsScreenState extends State<CISOSponsorsScreen> {

  List<SponsorData> sponsors = [];

  @override
  void initState() {
fetchCisoSponsors();
super.initState();
  }



  Future fetchCisoSponsors() async {
    final response = await DioFetchService().fetchCISOSponsors();

    setState(() {
      //isFetching=false;
    });

    List<dynamic> filteredData = response.data['data'].toList();





    if (response.statusCode == 200) {
      final rawData = response.data['data'].toList();
      print("Raw sponsr data is ${rawData.length}");

      List<SponsorData> sponsorsList = List<SponsorData>.from(filteredData.map((user) => SponsorData.fromJson(user)));


      setState(() {
        sponsors=sponsorsList;
        //  print(attendees![624].firstName);
        print(sponsors!.length);

      });
    } else {
      throw Exception('Failed to load data');

    }
  }

  @override
  Widget build(BuildContext context) {
    return  SafeArea(
      child: Scaffold(body: Stack(
        children: [
          CoolBackground(),
          Container(height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                Container(height:55,width:MediaQuery.of(context).size.width,child: Row(children: [
                  IconButton(onPressed: (){Navigator.of(context).pop();}, icon: Icon(Icons.chevron_left,color: Colors.black54,size: 35,)),
                  Spacer(),
                  const Text("MEET OUR SPONSORS", style: TextStyle(fontSize:17,fontWeight: FontWeight.w600 ,color:  Colors.black54),)
                  ,Spacer(),

                ],),),
                Divider(color: Colors.black,),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:Column(
                      children: [

                        Flexible(
                          child: ListView.builder(

                            padding:  const EdgeInsets.all(8),
                            itemCount: sponsors.length,
                            itemBuilder: (context, index) {
                              //  final Speaker speaker = sponsorData[index];

                              return Column(children: [sponsorWidget(context: context, sponsorAsset:"https://subscriptions.cioafrica.co/assets/${sponsors[index]!.logo!}",
                                degree: "${sponsors[index].degree!}°",
                                sponsorName:sponsors[index].sponsorName!,
                                sponsorBio:sponsors[index].about!, sponsorURL: sponsors![index]!.websites!.first.link!,

                              ),verticalSpace(height: 10)],);

                              //   speakerWidget(context: context, name: speaker.name,
                              //     title: speaker.title, bio: speaker.bio,imageURL: url
                              // );
                            },
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
