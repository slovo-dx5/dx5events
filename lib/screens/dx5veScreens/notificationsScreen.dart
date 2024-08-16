
import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, String>> notifications = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedNotifications = prefs.getStringList('notifications');
    if (storedNotifications != null) {
      setState(() {
        notifications = storedNotifications.map((notification) {
          var parts = notification.split(":");
          return {"title": parts[0], "body": parts[1], "timestamp": parts[2]};
        }).toList();
      });
    }
  }
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return "Unknown time";
    final DateTime dateTime = DateTime.parse(timestamp);

    // Format day with suffix (1st, 2nd, 3rd, etc.)
    String day = dateTime.day.toString();
    String suffix = "th";
    if (day.endsWith("1") && day != "11") suffix = "st";
    if (day.endsWith("2") && day != "12") suffix = "nd";
    if (day.endsWith("3") && day != "13") suffix = "rd";
    day = day + suffix;

    // Format month name
    String month = _monthName(dateTime.month);

    // Format time
    String hour = dateTime.hour > 12 ? (dateTime.hour - 12).toString() : dateTime.hour.toString();
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String period = dateTime.hour >= 12 ? "pm" : "am";

    return "$day $month, \n$hour:$minute$period";
  }

// Helper function to get the month name from the month number
  String _monthName(int month) {
    const List<String> months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(appBar:AppBar(title: Text("Notifications"),),
      body: ListView.builder(itemCount: notifications.length,

        itemBuilder: (context,index){
          int reversedIndex = notifications.length - 1 - index; //TO display latest notification first
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8),
            child: ListTile(title: Text(notifications[reversedIndex]["title"]?? "No Title",style: const TextStyle(
              fontWeight: FontWeight.w700,fontSize: 13.5
            ),),
              subtitle: Text(notifications[reversedIndex]["body"] ?? "No Body,",style: const TextStyle(

              ),),
            trailing:  Text(_formatTimestamp(notifications[reversedIndex]["timestamp"])),),
          ),
        ),
      );

    }),);
  }
}
