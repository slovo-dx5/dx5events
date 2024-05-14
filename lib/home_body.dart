
import 'package:dx5veevents/widgets/homePageWidget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';


class HomeBody extends StatefulWidget {
  String coverImagePath;
  String eventName;
  String eventDayOfWeek;
  String shortEventDescription;
  String eventLocation;
  String eventDate;
  String eventID; int eventDay;
  int eventMonth;
  int eventYear;

   HomeBody({super.key,   required this.eventDay,
     required this.eventMonth,
     required this.eventYear,required this.coverImagePath,required this.eventDate,required this.eventID, required this.eventName,required this.shortEventDescription,required this.eventDayOfWeek, required this.eventLocation});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final GlobalKey _one = GlobalKey();
  final GlobalKey _two = GlobalKey();
  final GlobalKey _three = GlobalKey();
  final GlobalKey _four = GlobalKey();
  bool isFirstTime = true;
  void checkFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isFirstTime = prefs.getBool('isFirstTimeHome') ?? true;

    if (isFirstTime) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ShowCaseWidget.of(context).startShowCase([
                _one,
                _two,
                _three,
                _four,
              ]));
      await prefs.setBool('isFirstTimeHome', false);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    checkFirstTime();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return HomePageWidget(eventDay: widget.eventDay, eventMonth: widget.eventMonth, eventYear: widget.eventYear,
      coverImagepath: widget.coverImagePath, eventName: widget.eventName,
      eventDayOfWeek: widget.eventDayOfWeek,
      shortEventDescription: widget.shortEventDescription,
      eventLocation: widget.eventLocation, eventID: widget.eventID, eventDate: widget.eventDate,);

  }
}
