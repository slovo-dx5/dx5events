// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:dx5veevents/dioServices/dioFetchService.dart';
// import 'package:dx5veevents/models/presentation_model.dart';
// import 'package:flutter/material.dart';
//
// import '../../constants.dart';
// import '../../dioServices/base_url.dart';
// import '../../models/speakersModel.dart';
// import '../../widgets/pdf_preview.dart';
//
// class PastPresentationsScreen extends StatefulWidget {
//   String eventName;
//   int eventID;
//   PastPresentationsScreen(
//       {super.key, required this.eventName, required this.eventID});
//
//   @override
//   State<PastPresentationsScreen> createState() =>
//       _PastPresentationsScreenState();
// }
// class _PastPresentationsScreenState extends State<PastPresentationsScreen> {
//   List<PresentationModel> fetchedPresentations = [];
//   List<PresentationModel> filteredPresentations = [];
//   bool isLoading = true;
//   String searchQuery = '';
//   bool searchBySpeaker = true;
//
//   // Cache for fetched speakers
//   Map<int, IndividualSpeaker?> speakerCache = {};
//
//   @override
//   void initState() {
//     super.initState();
//     fetchPresentations();
//   }
//
//   fetchPresentations() async {
//     try {
//       final response = await DioFetchService().fetchPresentation(
//           eventID: widget.eventID);
//
//       if (response.statusCode == 200) {
//         final data = PresentationResponse.fromJson(response.data);
//         setState(() {
//           fetchedPresentations = data.data;
//           filteredPresentations = data.data;
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       print('Error fetching presentations: $e');
//     }
//   }
//
//   Future<IndividualSpeaker?> fetchSpeakerById(int key) async {
//     // Return cached speaker if available
//     if (speakerCache.containsKey(key)) {
//       return speakerCache[key];
//     }
//
//     try {
//       final response =
//       await DioFetchService().fetchEventSpeakerByKey(speakerKey: key);
//       final speakersModel = SpeakersModel.fromJson(response.data);
//
//       for (var speaker in speakersModel.data) {
//         if (speaker.id == key) {
//           speakerCache[key] = speaker; // Cache the result
//           return speaker;
//         }
//       }
//     } catch (e) {
//       print('Error fetching speaker: $e');
//     }
//
//     speakerCache[key] = null; // Cache the null result to avoid repeated fetches
//     return null;
//   }
//
//   void updateSearch(String query) {
//     setState(() {
//       searchQuery = query;
//       if (searchQuery.isEmpty) {
//         filteredPresentations = fetchedPresentations;
//       } else {
//         filteredPresentations = fetchedPresentations.where((presentation) {
//           return presentation.topic
//               .toLowerCase()
//               .contains(searchQuery.toLowerCase());
//         }).toList();
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         title: const Text('CIO 100 2024 Presentations'),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(60),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     onChanged: updateSearch,
//                     decoration: InputDecoration(
//                       hintText:
//                           'Search by Topic',
//                       prefixIcon: const Icon(Icons.search),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : filteredPresentations.isEmpty
//           ? const Center(child: Text('No presentations available.'))
//           : Padding(
//         padding: const EdgeInsets.all(10),
//         child: ListView.builder(
//           itemCount: filteredPresentations.length,
//           itemBuilder: (context, index) {
//             final presentation = filteredPresentations[index];
//             return FutureBuilder(
//               future: fetchSpeakerById(presentation.speaker.key),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState ==
//                     ConnectionState.waiting) {
//                   // Display a temporary placeholder instead of text
//                   return const SizedBox(
//                     height: 80,
//                     child: Center(child: CircularProgressIndicator()),
//                   );
//                 } else if (snapshot.connectionState ==
//                     ConnectionState.done &&
//                     snapshot.data != null) {
//                   final speaker = snapshot.data!;
//                   return buildPresentationCard(presentation, speaker);
//                 } else {
//                   // Fallback when speaker details fail to load
//                   return buildPresentationCard(
//                       presentation, null);
//                 }
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget buildPresentationCard(
//       PresentationModel presentation, IndividualSpeaker? speaker) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: kPastEventColor.withOpacity(0.6),
//           border: Border.all(color: kPastEventColor),
//           borderRadius: BorderRadius.circular(15),
//         ),
//         child: Column(
//           children: [
//             if (speaker != null)
//               Row(
//                 children: [
//                   CachedNetworkImage(
//                     fit: BoxFit.cover,
//                     imageUrl:
//                     "${BaseURL.Baseurl}/assets/${speaker.photo}",
//                     progressIndicatorBuilder: (context, url, downloadProgress) =>
//                         SizedBox(
//                             height: 20,
//                             width: 20,
//                             child: CircularProgressIndicator(
//                                 value: downloadProgress.progress)),
//                     imageBuilder: (context, imageProvider) => CircleAvatar(
//                       radius: 30,
//                       backgroundImage: imageProvider,
//                     ),
//                   ),
//                   horizontalSpace(width: 10),
//                   Expanded(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           '${speaker.firstName} ${speaker.lastName}',
//                           style: kGreyTextStyle(fontsiZe: 15),
//                         ),
//                         Text(
//                           '${speaker.role} at ${speaker.company}',
//                           style: kNameTextStyle(fontsiZe: 12),
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 2,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             if (speaker == null) const Text('Speaker details not available'),
//             verticalSpace(height: 20),
//             Text(
//               presentation.topic,
//               style: TextStyle(fontSize: 15,fontWeight: FontWeight.w600)
//             ),
// verticalSpace(height: 15),
//             PdfViewerPage(
//               pdfUrl:
//               "${BaseURL.Baseurl}/assets/${presentation.presentationPdf}",
//               speaker: speaker?.firstName ?? 'Unknown',
//               eventName: widget.eventName,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
