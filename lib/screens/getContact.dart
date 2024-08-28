

import 'dart:convert';
import 'dart:io';

import 'package:dx5veevents/screens/saveContact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../dioServices/dioFetchService.dart';
import '../dioServices/dioPostService.dart';
import '../mainNavigationPage.dart';
import '../models/contactModel.dart';
import '../providers.dart';
import 'package:dx5veevents/constants.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';



class GetContact extends StatefulWidget {

  GetContact({key});

  @override
  State<GetContact> createState() => _GetContactState();
}

class _GetContactState extends State<GetContact> {
  final GlobalKey contactQrKey = GlobalKey();
  QRViewController? contactController;
  bool hasScanned=false;
  bool isSending=false;
  String sponsorID="";
  String? lastScannedCode;

  _onQRViewCreated(QRViewController controller)async {
    this.contactController = controller;
    controller.scannedDataStream.listen((scanData)async {
      print("scandata is ${scanData.code}");
      await controller.pauseCamera();
      fetchAndSaveAttendeeInfo(attendeeDAta: scanData.code);
      controller.resumeCamera();
    });
  }



  // Extracts the numerical ID from the attendeeData string.
  int  getAttendeeId({required attendeeData}) {
    var parts = attendeeData.split(':');
    return int.tryParse(parts.last) ?? 0; // Returns 0 if parsing fails
  }

  fetchAndSaveAttendeeInfo({required attendeeDAta})async{
     int AttendeeID=getAttendeeId(attendeeData: attendeeDAta);
     print("attendee is is ${AttendeeID}");
     var response = await DioFetchService().fetchSingleAttendeeFromAttendees(id: AttendeeID);
     var data = response.data["data"];
     //var data = response.data;
     print("data is ${data[0]["id"]}");

     if (data != null && data.isNotEmpty) {
       var attendeeDetails = data[0];
       PersistentNavBarNavigator.pushNewScreen(
         context,
         screen: SaveContact(
           firstName: attendeeDetails["firstName"],
           phone:  attendeeDetails["phone"],
           lastName:  attendeeDetails["lastName"],
           company: attendeeDetails['company'],
           role: attendeeDetails["role"],
           email: attendeeDetails["email"],
         ),
         withNavBar: false,
         pageTransitionAnimation: PageTransitionAnimation.slideRight,
       );



     }


  }

  @override
  void dispose() {
    contactController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("dx5ve Contact SCANNER"),automaticallyImplyLeading: true,),
        body: Visibility(
          replacement: const Center(child: SpinKitCircle(color: kCIOPink,size: 100,),),
          visible: isSending==false,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Text("Position the scanner towards another attendee's "
                    "badge to get their contact details", style: TextStyle(fontSize: 18),textAlign: TextAlign.center,),

                verticalSpace(height: 40),
                Container(
                  height: 350,
                  width: 350,  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius:
                    const BorderRadius.all(Radius.circular(12))),
                  child: ClipRRect(borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: QRView(
                      key: contactQrKey,
                      onQRViewCreated: _onQRViewCreated,
                      overlay: QrScannerOverlayShape(
                        borderColor: Colors.orange,
                        borderRadius: 10,
                        borderLength: 30,
                        borderWidth: 10,
                        cutOutSize: 350,
                      ),

                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
