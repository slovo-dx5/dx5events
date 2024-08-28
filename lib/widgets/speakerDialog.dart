import 'dart:ui';

import 'package:flutter/material.dart';class SpeakerDialog extends StatefulWidget {
  @override
  _SpeakerDialogState createState() => _SpeakerDialogState();
}

class _SpeakerDialogState extends State<SpeakerDialog> {
  bool _showDialog = false;

  void _toggleDialog(bool show) {
    setState(() {
      _showDialog = show;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blur Background Dialog'),
      ),
      body: Stack(
        children: [
          // Your main content goes here.
          const Center(
            child: Text('Tap the button to show dialog.'),
          ),

          // When _showDialog is true, display the blurred overlay and dialog.
          if (_showDialog) ...[
            // Blurring the background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),

            // The dialog itself
            Center(
              child: Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('This is a dialog'),
                      ElevatedButton(
                        onPressed: () => _toggleDialog(false),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _toggleDialog(true),
        child: Icon(Icons.open_in_new),
      ),
    );
  }
}