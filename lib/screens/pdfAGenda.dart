import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PDFViewerScreen extends StatefulWidget {
  final String pdfAssetPath; // Path to PDF file in assets or downloaded location

  const PDFViewerScreen({Key? key, required this.pdfAssetPath}) : super(key: key);

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? _localPDFPath;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    // Copy PDF file from assets to a local path
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/${widget.pdfAssetPath.split('/').last}");
      if (!file.existsSync()) {
        final data = await DefaultAssetBundle.of(context).load(widget.pdfAssetPath);
        await file.writeAsBytes(data.buffer.asUint8List());
      }
      setState(() {
        _localPDFPath = file.path;
      });
    } catch (e) {
      print("Error loading PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true,
        leading: IconButton(onPressed: () { Navigator.of(context).pop(); }, icon: Icon(Icons.arrow_back_ios),color: kPrimaryColor,),
        title: const Text("2024 Africa CISO Summit AGENDA"),
      ),
      body: _localPDFPath == null
          ? const Center(child: CircularProgressIndicator())
          : PDFView(
        filePath: _localPDFPath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onRender: (pages) {
          print("PDF Rendered with $pages pages");
        },
        onError: (error) {
          print("Error: $error");
        },
        onPageError: (page, error) {
          print("Page $page Error: $error");
        },
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PDFViewerScreen(pdfAssetPath: "assets/sample.pdf"),
    );
  }
}
