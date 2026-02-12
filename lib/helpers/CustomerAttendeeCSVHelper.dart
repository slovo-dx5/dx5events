
import 'package:csv/csv.dart';
import 'package:dx5veevents/dioServices/dioPostService.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';

import '../models/customerEventModel.dart';




class CSVHelper extends StatefulWidget {
  const CSVHelper({super.key});

  @override
  State<CSVHelper> createState() => _CSVHelperState();
}

class _CSVHelperState extends State<CSVHelper> {
  @override
  void initState() {
    loadAndUploadCustomerAttendees('assets/aff.csv');
    super.initState();
  }

  Future<List<CustomerContact>> loadAndUploadCustomerAttendees(String path) async {
    final input = await rootBundle.loadString(path);
    List<List<dynamic>> rows = const CsvToListConverter().convert(input);

    // Initialize a counter for attendeeId
    int attendeeId = 1;

    // Skip the header row and map rows to Contact objects
    List<CustomerContact> contacts = rows.skip(1).map((row) {
      return CustomerContact.fromCsv(csvRow: row.cast<dynamic>(), attendeeId: attendeeId++, eventID: 25, eventName: 'Africa Fintech Festival',);
    }).toList();

    // Print all contacts
    contacts.forEach((contact) {
      print('Name: ${contact.name}, Email: ${contact.email}, ROle: ${contact.company_role}, Phone: ${contact.phone}' 'AttendeId: ${contact.attendeeId}');
    });

    await uploadCustomerAteendees(CustomerContacts: contacts);

    return contacts;
  }

  uploadCustomerAteendees({required List<CustomerContact> CustomerContacts,})async{
    for(CustomerContact customerContact in CustomerContacts){
      try{await DioPostService().postCustomerInfo(body: {
        "name": customerContact.name ?? "unspecified",
        "email": customerContact.email ?? "unspecified" ,
        "company_role": customerContact.company_role ??"Unspecified",
        "eventID": 25,
        "attendeeId": customerContact.attendeeId,
        "eventName": "Africa Fintech Festival",
        "phone": customerContact.phone,

      }, context: context);print("Upload success");}
      catch(e){print("Customer upload error is $e");}
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

