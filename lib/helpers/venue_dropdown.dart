import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants.dart';


class VenueDropdown extends StatefulWidget {
  const VenueDropdown({
    required this.onVenuePicked,
    super.key,

  });


  final ValueChanged<String?> onVenuePicked;


  @override
  State<VenueDropdown> createState() => _VenueDropdownState();
}



class _VenueDropdownState extends State<VenueDropdown> {
  String? venue;

  List<String> allVenues = [
    "TABLE 1",
    "TABLE 2",
    "TABLE 3",
    "TABLE 4",
    "TABLE 5",
    "TABLE 6",
    "TABLE 7",
    "TABLE 8",
    "TABLE 9",
    "TABLE 10",

  ];

  List<DropdownMenuItem<String>> getDropdownItems() {


    List<DropdownMenuItem<String>> dropdownItems = [];
    for (String tableString in allVenues) {

      // Adjusting the year, month, and day to match the current date for proper comparison



        dropdownItems.add(DropdownMenuItem(
          value: tableString,
          child: Text(tableString),
        ));

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
      value: venue,
      items:  getDropdownItems(),
      // onChanged: widget.onChanged,
      onChanged: (String? newValue){
        setState(() {
          venue=newValue;
        });
        widget.onVenuePicked(newValue);
      },

    );
  }
}