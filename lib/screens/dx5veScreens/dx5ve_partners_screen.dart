import 'dart:convert';

import 'package:dx5veevents/models/eventModel.dart';
import 'package:dx5veevents/models/partners_model.dart';
import 'package:flutter/material.dart';

import '../../dioServices/dioFetchService.dart';
import '../../models/sponsor_data_model.dart';
import '../../widgets/cool_background.dart';
import '../../widgets/sponsor_widget.dart';

class CISOPartnersScreen extends StatefulWidget {
  String eventID;
  CISOPartnersScreen({super.key, required this.eventID});

  @override
  State<CISOPartnersScreen> createState() => _CISOPartnersScreenState();
}

class _CISOPartnersScreenState extends State<CISOPartnersScreen> {
  List<PartnerData> partners = [];
  List<PartnerAssociation> neoPartners = [];
  List<PartnerData> partnerList = [];
  bool isFetching = false;

  @override
  void initState() {
    fetchEventData();
    super.initState();
  }



  Future fetchPartnerById({required int key}) async {
    try {
      final response = await DioFetchService().fetchEventPartners();
      final partnerModel = RootPartnerDataModel.fromJson(response.data);

      // Manually find the speaker to allow returning null.
      for (var partner in partnerModel.data!) {
        if (partner.id == key) {
          return partner;
        }
      }
      return null; // Explicitly return null if no speaker matches the key.
    } catch (e) {
      print(e);
      return null;
    }
  }

  fetchEventData() async {
    setState(() {
      isFetching = true;
    });
    final response =
        await DioFetchService().fetchEvents(eventID: widget.eventID);
    final Map<String, dynamic> responseData = response.data['data'];

    final List<dynamic> partnersData = responseData['partners'];

    for (var partnerData in partnersData) {
      neoPartners.add(PartnerAssociation.fromJson(partnerData));
    }

    for (var partner in neoPartners) {
      await fetchPartnerById(key: partner.partners.key).then((receivedPartner) {
        partnerList.add(receivedPartner);
      });

      /// print('Sponsor Key: ${sponsor.sponsor.key}, Category: ${sponsor.category}');
    }
    setState(() {
      isFetching = false;
    });
    for (var partner in partnerList) {
      print("Partner is ${partner.partnerName}");
      print("about is ${partner.about}");
      print("website is ${partner.website}");
      print("Partner is ${partner.logo}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            CoolBackground(),
            Container(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  Container(
                    height: 55,
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      children: [
                        IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(
                              Icons.chevron_left,
                              color: Colors.black54,
                              size: 35,
                            )),
                        Spacer(),
                        const Text(
                          "MEET OUR PARTNERS",
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54),
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                  const Divider(
                    color: Colors.black,
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Flexible(
                            child: ListView.builder(
                              padding: EdgeInsets.all(8),
                              itemCount: partnerList.length,
                              itemBuilder: (context, index) {
                                //  final Speaker speaker = sponsorData[index];

                                return sponsorWidget(
                                  context: context,
                                  sponsorAsset:
                                      "https://subscriptions.cioafrica.co/assets/${partnerList[index].transparent_Logo ?? partnerList[index].logo}",
                                  degree: "",
                                  sponsorName: partnerList[index].partnerName!,
                                  sponsorBio: partnerList[index].about ?? "",
                                  sponsorURL: partnerList[index].website??"",
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
        ),
      ),
    );
  }
}
