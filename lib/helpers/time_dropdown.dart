import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants.dart';


class TimeDropdown extends StatefulWidget {
  const TimeDropdown({
    required this.onTimePicked,
    super.key,

  });


  final ValueChanged<String?> onTimePicked;


  @override
  State<TimeDropdown> createState() => _TimeDropdownState();
}



class _TimeDropdownState extends State<TimeDropdown> {
  String? time;

  List<String> allTimes = [
    "10:00 AM",
    "1:00 PM",  "1:30 PM",
    "4:30 PM", "5:00 PM", "5:30 PM", "6:00 PM",
  ];

  List<DropdownMenuItem<String>> getDropdownItems() {
    DateTime now = DateTime.now();
    DateFormat format = DateFormat("h:mm a");

    List<DropdownMenuItem<String>> dropdownItems = [];
    for (String timeString in allTimes) {
      DateTime time = format.parse(timeString);
      // Adjusting the year, month, and day to match the current date for proper comparison
      time = DateTime(now.year, now.month, now.day, time.hour, time.minute);

      if (time.isAfter(now)) {
        dropdownItems.add(DropdownMenuItem(
          value: timeString,
          child: Text(timeString),
        ));
      }
    }
    return dropdownItems;
  }

  @override
  void initState() {
    super.initState();
    //time = "7:00 AM"; // Set mp4 as the default value
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String?>(
      style: const TextStyle(color: kPrimaryColor),
      //dropdownColor: kDarkScaffold,
      value: time,
      items:  getDropdownItems(),
      // onChanged: widget.onChanged,
      onChanged: (String? newValue){
        setState(() {
          time=newValue;
        });
        widget.onTimePicked(newValue);
      },

    );
  }
}