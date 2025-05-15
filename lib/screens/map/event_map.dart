import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapIframePage extends StatefulWidget {
  @override
  _MapIframePageState createState() => _MapIframePageState();
}

class _MapIframePageState extends State<MapIframePage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse("https://www.residencetechnologies.com/home/resident_map/"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Resident Map")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
