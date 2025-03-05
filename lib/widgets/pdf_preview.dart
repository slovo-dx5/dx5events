import 'package:dx5veevents/dioServices/dioFetchService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../constants.dart';
import '../screens/pastEvents/cachedPDFView.dart';
import '../screens/pdfAGenda.dart';
import 'package:flutter_downloader/flutter_downloader.dart';


class PdfViewerPage extends StatelessWidget {
  final String pdfUrl;
  final String eventName;
  final String speaker;

  const PdfViewerPage({super.key,required this.pdfUrl,required this.speaker,
    required this.eventName});

  // Function to view PDF in full screen
  void _viewPdf(BuildContext context, String pdfUrl) {
    PersistentNavBarNavigator.pushNewScreen(
      context,
      screen:  PDFViewerCachedFromUrl(url: pdfUrl,
      ),
      withNavBar: false,
      pageTransitionAnimation: PageTransitionAnimation.slideRight,
    );
  }

  // Function to download the PDF
  Future _downloadPdf(BuildContext context, String pdfUrl) async {
    var status = await Permission.photos.status;
    print("Permissin status is ${status}");
    if (!status.isGranted) {
      status = await Permission.photos.request();
      if (!status.isGranted) {
        return false; // Permission denied
      }
    }

    // For Android 11 (API level 30) and above
    if (Platform.isAndroid) {
      var manageStatus = await Permission.manageExternalStorage.status;
      if (!manageStatus.isGranted) {
        manageStatus = await Permission.manageExternalStorage.request();
        if (!manageStatus.isGranted) {
          return false; // Permission denied
        }
      }
    }
    await FlutterDownloader.enqueue(
      url: pdfUrl,
      savedDir: '/storage/emulated/0/Download',
      showNotification: true, // show download progress in status bar (for Android)
      openFileFromNotification: true, // click on notification to open downloaded file (for Android)
      saveInPublicStorage: true
    );
    // try {
    //   final response = await DioFetchService().fetchPresentationPDF(presentationURL: pdfUrl);
    //   if (response.statusCode == 200) {
    //     final file = File('/storage/emulated/0/Download/$speaker${eventName}presentation.pdf');
    //     final bytes = (response.data ).toList<int>;
    //     await file.writeAsBytes(bytes);
    //
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Presentation saved to your downloads folder')),
    //     );
    //
    //   } else {
    //     throw Exception('Failed to download PDF');
    //   }
    // } catch (e) {
    //   print("Error is $e");
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Error downloading PDF: $e')),
    //   );
    // }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      height: 200,
      width: MediaQuery.of(context).size.width * 0.9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // PDF Widget
            const PDF().cachedFromUrl(
              pdfUrl,
              placeholder: (progress) => Center(
                child: CircularProgressIndicator(value: progress / 100),
              ),
              errorWidget: (error) {
                print('Failed to load PDF: $error');
                return Center(
                  child: Text('Failed to load PDF: $error'),
                );
              },
            ),

            // Buttons overlay
            Positioned(
              bottom: 10,
              left: 10,
              child: SizedBox(width: MediaQuery.of(context).size.width*0.4,child: primaryButton(
                context: context,
                onPressedFunction: () { _viewPdf(context, pdfUrl); }, buttonText: 'View Presentation',
              ),)
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: SizedBox(width: MediaQuery.of(context).size.width*0.4,child: primaryButton(
                context: context,
                onPressedFunction: () {
                  Fluttertoast.showToast(msg: "Download started");

                  _downloadPdf(context, pdfUrl); }, buttonText: 'Download Presentation',
              ),))
          ],
        ),
      ),
    );


  }
}
