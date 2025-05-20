import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../dioServices/base_url.dart';
import '../../dioServices/dioFetchService.dart';
import '../../models/eventModel.dart';
import '../../models/sponsor_data_model.dart';
import '../../widgets/sponsor_widget.dart';

class CISOSponsorsScreen extends StatefulWidget {
  final String eventID;
  const CISOSponsorsScreen({required this.eventID, super.key});

  @override
  State<CISOSponsorsScreen> createState() => _CISOSponsorsScreenState();
}

class _CISOSponsorsScreenState extends State<CISOSponsorsScreen> {
  // Single future to handle all data loading
  late Future<Map<int, List<dynamic>>> _sponsorDataFuture;

  @override
  void initState() {
    super.initState();
    _sponsorDataFuture = _loadSponsorsData();
  }

  // Combined data loading function that returns a single Future
  Future<Map<int, List<dynamic>>> _loadSponsorsData() async {
    // Load event and sponsors data in parallel
    final eventFuture = DioFetchService().fetchEvents(eventID: widget.eventID);
    final sponsorsFuture = DioFetchService().fetchEventSponsors();

    // Wait for both futures to complete
    final results = await Future.wait([eventFuture, sponsorsFuture]);

    final eventResponse = results[0];
    final sponsorsResponse = results[1];

    // Process event data
    final Map<String, dynamic> eventData = eventResponse.data['data'];
    final List<dynamic> sponsorsData = eventData['sponsors'];
    final List<SponsorAssociation> eventSponsors = sponsorsData
        .map((sponsorData) => SponsorAssociation.fromJson(sponsorData))
        .toList();

    // Process all sponsors data
    final sponsorsModel = RootSponsorDataModel.fromJson(sponsorsResponse.data);
    final Map<int, dynamic> sponsorsById = {};

    // Create a lookup map for sponsors by ID for O(1) access
    if (sponsorsModel.data != null) {
      for (var sponsor in sponsorsModel.data!) {
        sponsorsById[sponsor.id!] = sponsor;
      }
    }

    // Match event sponsors with full sponsor details
    final Map<int, List<dynamic>> result = {};
    int index = 0;

    for (var association in eventSponsors) {
      final sponsorDetails = sponsorsById[association.sponsor.key];
      if (sponsorDetails != null) {
        result[index] = [association.category, sponsorDetails];
        index++;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
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
                          icon: Icon(Icons.chevron_left, color: Colors.black54, size: 35),
                        ),
                        Spacer(),
                        const Text(
                          "MEET OUR SPONSORS",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.black),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Flexible(
                            child: FutureBuilder<Map<int, List<dynamic>>>(
                              future: _sponsorDataFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error loading sponsors: ${snapshot.error}'),
                                  );
                                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Center(
                                    child: Text("No sponsors available"),
                                  );
                                } else {
                                  final sponsorMap = snapshot.data!;
                                  return GridView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: sponsorMap.length,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 0.75,
                                    ),
                                    itemBuilder: (context, index) {
                                      final entry = sponsorMap.entries.elementAt(index);
                                      final sponsorData = entry.value;

                                      return Column(
                                        children: [
                                          sponsorWidget(
                                            context: context,
                                            sponsorAsset: "${BaseURL.Baseurl}/assets/${sponsorData[1].transparent_logo ?? sponsorData[1].logo}",
                                            degree: "${sponsorData[0]}°",
                                            sponsorName: sponsorData[1].sponsorName!,
                                            sponsorBio: sponsorData[1].about??"",
                                            sponsorURL: sponsorData[1].websites!.first.link!,
                                          ),
                                          const Divider(),
                                          verticalSpace(height: 10),
                                        ],
                                      );
                                    },
                                  );
                                }
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