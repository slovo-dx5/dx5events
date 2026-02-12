
import 'package:csv/csv.dart';
import 'package:dx5veevents/dioServices/dioPostService.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';

import '../models/customerSpeakerModel.dart';




class CustomerSpeakerCSVHelper extends StatefulWidget {
  const CustomerSpeakerCSVHelper({super.key});

  @override
  State<CustomerSpeakerCSVHelper> createState() => _CustomerSpeakerCSVHelperState();
}

class _CustomerSpeakerCSVHelperState extends State<CustomerSpeakerCSVHelper> {
  @override
  void initState() {
    loadAndUploadCustomerSpeakers('assets/affspeakers.csv');
    super.initState();
  }

  Future<List<CustomerSpeaker>> loadAndUploadCustomerSpeakers(String path) async {
    final input = await rootBundle.loadString(path);
    List<List<dynamic>> rows = const CsvToListConverter().convert(input);

    // Initialize a counter for attendeeId
    int attendeeId = 1;

    // Skip the header row and map rows to Contact objects
    List<CustomerSpeaker> speakers = rows.skip(1).map((row) {
      return CustomerSpeaker.fromCsv(csvRow: row.cast<dynamic>(), attendeeId: attendeeId++, eventID: 25, eventName: 'Africa Fintech Festival',);
    }).toList();

    // Print all contacts
    speakers.forEach((contact) {
      print('Name: ${contact.first_name}, Email: ${contact.email}, ROle: ${contact.role}, Phone: ${contact.phone}' );
    });

    await uploadCustomerSpeakers( CustomerSpeakers: speakers);

    return speakers;
  }

  uploadCustomerSpeakers({required List<CustomerSpeaker> CustomerSpeakers,})async{
    for(CustomerSpeaker customerSpeaker in CustomerSpeakers){
      try{await DioPostService().postCustomerSpeakerInfo(body: {
        "first_name": customerSpeaker.first_name ?? "unspecified",
        "last_name": "",
        "work_email": customerSpeaker.email ,
        "company": customerSpeaker.company ??"Unspecified",


        "work_phone": customerSpeaker.phone,
        "role": customerSpeaker.role,
        "bio": customerSpeaker.bio,

        "linkedin_profile": "",
        "allowed_contact_methods": ["Email"],

      }, context: context);print("Upload success");}
      catch(e){print("Customer upload error is $e");}
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

