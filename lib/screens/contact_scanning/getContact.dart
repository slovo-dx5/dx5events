

import 'dart:convert';
import 'dart:io';

import 'package:dx5veevents/screens/saveContact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart' ;
import 'package:shared_preferences/shared_preferences.dart';

import '../../dioServices/dioFetchService.dart';
import '../../dioServices/dioPostService.dart';
import '../../helpers/analytics_helper.dart';
import '../../mainNavigationPage.dart';
import '../../models/contactModel.dart';
import '../../providers.dart';
import 'package:dx5veevents/constants.dart';

import 'package:permission_handler/permission_handler.dart';
import 'scanned_contacts.dart';



class GetContact extends StatefulWidget {
int ownerID;
  GetContact({key,required this.ownerID});

  @override
  State<GetContact> createState() => _GetContactState();
}

class _GetContactState extends State<GetContact> with SingleTickerProviderStateMixin {
  final GlobalKey contactQrKey = GlobalKey();
  QRViewController? contactController;
  bool hasScanned=false;
  bool isSending=false;
  String sponsorID="";
  String? lastScannedCode;
  bool isDialogShown = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _showAlertDialogOnce();

    // Listen to tab changes to pause/resume camera
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        // Scanner tab - resume camera if not already scanning
        if (!hasScanned) {
          contactController?.resumeCamera();
        }
      } else {
        // History tab - pause camera
        contactController?.pauseCamera();
      }
    });
  }

  sendSponsorData()async{
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    final response=await DioPostService().postSponsorData(body: {
      "sponsorid": sponsorID,
      "firstname": profileProvider.firstName,
      "lastname": profileProvider.lastName,
      "company": profileProvider.company,
      "phone": profileProvider.phone,
      "email": profileProvider.email,
      "position": profileProvider.role
    }, context: context);
    await Dx5veAnalytics().logdx5veEvent(eventName: "sponsorBoothScanned");

    if(Platform.isIOS)await contactController?.pauseCamera();
    if(response.statusCode==200){
      if(Platform.isIOS)await contactController?.pauseCamera();
      Fluttertoast.showToast(msg: "Success");
      Navigator.of(context).pop(

      );
    }else{
      Fluttertoast.showToast(msg: "Error: Check your internet");
      Navigator.of(context).pop();

      setState(() {
        isSending=false;
        Navigator.of(context).pop();
      });
    }

  }

  _onQRViewCreated(QRViewController controller)async {
    this.contactController = controller;

    controller.scannedDataStream.listen((scanData)async {
      // Prevent processing the same QR code multiple times
      if (hasScanned || scanData.code == lastScannedCode) {
        return;
      }

      // Mark as scanned and store the code
      setState(() {
        hasScanned = true;
        lastScannedCode = scanData.code;
      });

      // Pause camera immediately to prevent further scans
      await controller.pauseCamera();

      if (scanData.code!.startsWith("sponsor")) {
        setState(() {
          isSending = true;
          sponsorID = scanData.code!;
        });
        await sendSponsorData();
        // Reset for next scan after sponsor data is sent
        setState(() {
          hasScanned = false;
          lastScannedCode = null;
        });
      } else {
        // For attendee scans, navigate without resuming camera
        await fetchAndSaveAttendeeInfo(attendeeDAta: scanData.code);
      }
    });
  }



  // Extracts the numerical ID from the attendeeData string.
  int  getAttendeeId({required attendeeData}) {
    var parts = attendeeData.split(':');
    return int.tryParse(parts.last) ?? 0; // Returns 0 if parsing fails
  }

  fetchAndSaveAttendeeInfo({required attendeeDAta})async{
     int AttendeeID=getAttendeeId(attendeeData: attendeeDAta);
     var response = await DioFetchService().fetchSingleAttendeeFromAttendees(id: AttendeeID);
     var data = response.data["data"];
     await Dx5veAnalytics().logdx5veEvent(eventName: "contactSaved");



     if (data != null && data.isNotEmpty) {
       var attendeeDetails = data[0];
       await PersistentNavBarNavigator.pushNewScreen(
         context,
         screen: SaveContact(
           firstName: attendeeDetails["firstName"],
           phone:  attendeeDetails["phone"],
           lastName:  attendeeDetails["lastName"],
           company: attendeeDetails['company'],
           role: attendeeDetails["role"],
           email: attendeeDetails["email"], ownerID: widget.ownerID,
         ),
         withNavBar: false,
         pageTransitionAnimation: PageTransitionAnimation.slideRight,
       ).then((_) {
         // Reset scanning state when user returns to allow new scans
         setState(() {
           hasScanned = false;
           lastScannedCode = null;
         });
         contactController?.resumeCamera();
       });
     }


  }

  Future<void> _showAlertDialogOnce() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasShownDialog = prefs.getBool('hasShownDialog') ?? false;

    if (!hasShownDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: kLightAppbar,
              title: const Center(child: Text("Alert!",style: TextStyle(color: kKeyShadowRed,fontWeight: FontWeight.w700,),)),
              content: const Text("Remember to notify someone before trying to get "
                  "their details.\n\nThis message won't be shown again.",style: TextStyle(color: kToggleDark,),),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      });
      await prefs.setBool('hasShownDialog', true);
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    contactController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Contact Scanner"),
          leading: IconButton(
            onPressed: (){Navigator.of(context).pop();},
            icon: const Icon(Icons.arrow_back),
            color: kCIOPink,
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: kCIOPink,
            labelColor: kCIOPink,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(
                icon: Icon(Icons.qr_code_scanner),
                text: "Scanner",
              ),
              Tab(
                icon: Icon(Icons.history),
                text: "History",
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Scanner Tab
            _buildScannerTab(),
            // History Tab
            ScannedContactsScreen(ownerID: widget.ownerID),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerTab() {
    return Visibility(
      replacement: const Center(child: SpinKitCircle(color: kCIOPink,size: 100,),),
      visible: isSending==false,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text(
              "Position the scanner towards another attendee's "
              "badge to get their contact details",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            verticalSpace(height: 40),
            Container(
              height: 350,
              width: 350,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: const BorderRadius.all(Radius.circular(12))
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
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
    );
  }
}
