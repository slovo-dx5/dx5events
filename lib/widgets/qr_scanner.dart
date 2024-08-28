

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../dioServices/dioPostService.dart';
import '../mainNavigationPage.dart';
import '../providers.dart';
import 'package:dx5veevents/constants.dart';



class SponsorScanner extends StatefulWidget {
  String firstName;
   String lastName;
   String company;
   String email;
   String phone;
   String position;
   SponsorScanner({required this.firstName,required this.phone, required this.lastName, required this.email,required this.company, required this.position,key});

  @override
  State<SponsorScanner> createState() => _SponsorScannerState();
}

class _SponsorScannerState extends State<SponsorScanner> {
  final GlobalKey qrKey = GlobalKey();
  QRViewController? controller;
  bool hasScanned=false;
  bool isSending=false;
  String sponsorID="";
  String? lastScannedCode;

   _onQRViewCreated(QRViewController controller)async {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (lastScannedCode != scanData.code && !isSending) {
        if (scanData.code!.startsWith("sponsor")) {
          setState(() {
            isSending = true;

            sponsorID = scanData.code!;
          });
          sendSponsorData();
        } else if (scanData.code!.startsWith("checkin")) {
          setState(() {
            isSending = true;
          });
          sendAttendeeData(qrContent: scanData.code);
        }
      }
    });
  }
  
  sendSponsorData()async{
    final response=await DioPostService().postSponsorData(body: {
      "sponsorid": sponsorID,
      "firstname": widget.firstName,
      "lastname": widget.lastName,
      "company": widget.company,
      "phone": widget.phone,
      "email": widget.email,
      "position": widget.position
    }, context: context);
    if(Platform.isIOS)await controller?.pauseCamera();
    if(response.statusCode==200){
      if(Platform.isIOS)await controller?.pauseCamera();
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

  sendAttendeeData({required qrContent})async{
    final response=await DioPostService().postCheckinData(body: {
      "email": widget.email,
      "printerId": qrContent,
     
    }, context: context);
    if(Platform.isIOS)await controller?.pauseCamera();
    if(response.statusCode==200){
      if(Platform.isIOS)await controller?.pauseCamera();
      Fluttertoast.showToast(msg: "Successfully checked in");
      Navigator.of(context).pop(

      );setState(() {
        isSending=false;
      });
    }else{Fluttertoast.showToast(msg: "Error: Check your internet connection");
      Navigator.of(context).pop();
    setState(() {
      isSending=false;  Navigator.of(context).pop();
    });

  }}
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("dx5ve Events QR SCANNER"),automaticallyImplyLeading: true,),
        body: Visibility(
          replacement: const Center(child: SpinKitCircle(color: kCIOPink,size: 100,),),
          visible: isSending==false,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  height: 350,
                  width: 350,  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius:
                    const BorderRadius.all(Radius.circular(12))),
                  child: ClipRRect(borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: QRView(
                      key: qrKey,
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
