import 'package:flutter/material.dart';

import '../constants.dart';

Future<void> infoDialog(
    {required BuildContext context, required String dialogText}) async {
  // final themeProvider = Provider.of<ThemeProvider>(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button for close dialog!
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: kToggleLight,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        content: Text(
          dialogText,
          textAlign: TextAlign.center,
          style: const TextStyle(color: kToggleDark),
        ),
        actions: <Widget>[
          Center(
            child: SizedBox(
              width: 150,
              child: ElevatedButton(
                child: const Text(
                  'Got it',
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      );
    },
  );
}