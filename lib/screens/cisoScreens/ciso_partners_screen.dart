
import 'dart:convert';

import 'package:dx5veevents/models/partners_model.dart';
import 'package:flutter/material.dart';

import '../../dioServices/dioFetchService.dart';
import '../../models/sponsor_data_model.dart';
import '../../widgets/cool_background.dart';
import '../../widgets/sponsor_widget.dart';
class CISOPartnersScreen extends StatefulWidget {
  const CISOPartnersScreen({super.key});

  @override
  State<CISOPartnersScreen> createState() => _CISOPartnersScreenState();
}

class _CISOPartnersScreenState extends State<CISOPartnersScreen> {

  List<PartnerData> partners = [];

  @override
  void initState() {
    fetchCisoPartners();
    super.initState();
  }



  Future fetchCisoPartners() async {
    final response = await DioFetchService().fetchCISOPartners();

    setState(() {
      //isFetching=false;
    });

    List<dynamic> filteredData = response.data['data'].toList();





    if (response.statusCode == 200) {
      final rawData = response.data['data'].toList();

      List<PartnerData> partnersList = List<PartnerData>.from(filteredData.map((user) => PartnerData.fromJson(user)));


      setState(() {
        partners=partnersList;
        //  print(attendees![624].firstName);
        print(partners!.length);

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
                  const Text("MEET OUR PARTNERS", style: TextStyle(fontSize:17,fontWeight: FontWeight.w600 ,color:  Colors.black54),)
                  ,Spacer(),

                ],),),
                Divider(color: Colors.black,),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:Column(
                      children: [

                        Flexible(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              mainAxisSpacing: 25,
                              crossAxisSpacing:25,
                              crossAxisCount: 2,
                              childAspectRatio: 4/2,
                            ),
                            padding:  EdgeInsets.all(8),
                            itemCount: partners.length,
                            itemBuilder: (context, index) {
                              //  final Speaker speaker = sponsorData[index];

                              return sponsorWidget(context: context, sponsorAsset:"https://subscriptions.cioafrica.co/assets/${partners[index]!.logo!}",
                                degree: "",
                                sponsorName:partners[index].partnerName!,
                                sponsorBio:partners[index].about!, sponsorURL: partners![index]!.website!,

                              );

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
