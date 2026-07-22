import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dx5veevents/screens/dx5veScreens/dx5veIndividualAttendee.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';


// Temporary feature flags — flip back to true to re-enable.
const bool kGalleryFeatureEnabled = true;
const bool kShopFeatureEnabled = false;

const kIconBlue = Color(0xFF2398cd);
const kIconPurple = Color(0xFF8f3b9d);
const kIconYellow = Color(0xFFd59a3e);
const kIconPink = Color(0xFFbe6060);
const kIconDeepBlue = Color(0xFF2f518e);

///Primary colors
const kPrimaryLight = Color(0xFFA3CFCB);
const kScaffoldColor = Color(0xFFededf5);

///Dark theme
//Backgrounds
//const kMainBlue = Color(0xFF3a4764);
const kDarkScaffold = Color(0xFF0d0d0d);

const kToggleDark = Color(0xFF161616);
const kScreenDark = Color(0xFF262626);
const kDarkCard = Color(0xFF262626);
const kDarkAppbar = Color(0xFF262626);
const kDarkFill = Color(0xFF201F26);
//const kScreenBlue = Color(0xFF182034);

//Keys

const kKeyRedBG = Color(0xFFff0000);
const kKeyShadowRed = Color(0xFF93261a);
const kLightGrayishOrange = Color(0xFFeae3dc);
const kGrayishOrange = Color(0xFFb4a597);
const kPastEventColor = Color(0xFFE8DBC9);
const kPastEventBorder = Color(0xFFCE8D51);
const kRightBubble = Color(0xFFdfdff6);
const kLeftBubble = Color(0xFFe9ebef);

//Text
const kGrayishBlueText = Color(0xFF444b5a);
const kWhiteText = Color(0xFFffffff);

///Light Theme
//Backgrounds
const kToggleLight = Color(0xFFd1cccc);
const kScreenGray = Color(0xFFededed);

const kLightAccent = Color(0xFFfa9500);

const kLighterGreenAccent = Color(0xFFc9ccc5);
const kDarkBold = Color(0xFFa7a7a7);
const kLightDisabledColor = Color(0xFFadadad);
const kGreyAgenda = Color(0xFF1C1B21);

//Keys
// const kKeyBackgroundCyan = Color(0xFF377f86);
const kLightCardColor = Color(0xFFffffff);
// const kKeyShadowCyan = Color(0xFF1b5f65);
const kKeyOrangeBG = Color(0xFFca5502);
// const kKeyOrangeShadow = Color(0xFF893901);
// const kLightGrayishYellow = Color(0xFFe5e4e1);
// const kDarkGrayishOrange = Color(0xFFa69d91);

//Text
const kDarkGrayishYellow = Color(0xFF35352c);
const kLightBoldText = Color(0xFF212121);
const kLightNormalText = Color(0xFF656565);

const kSuccessGreen = Color(0xFF4CAF50);
const kLogoutRed = Color(0xFFFF7171);

const kPrimaryColor = Color(0xFF44A0D3);

const kGoldColor = Color(0xFFd4af37);
const kScaffoldBackground = Color(0xFFF3F3F8);
const kLightAppbar = Color(0xFFF5F6FA);
Color kPrimaryColorLight = const Color(0xFF44A0D3).withOpacity(0.25);

const kWhiteColor = Colors.white;

const kPrimaryBlueColor = Color(0xFF3297F4);
const kPrimaryLightGrey = Color(0xFFD4D4D4);

const kTextColorBlack = Color(0xFF000000);
Color kTextColorBlackLighter = const Color(0xFF000000).withOpacity(0.75);
const kTextColorGrey = Color(0xFF757575);
const kTextColorNavy = Color(0xFF003665);

const kCIOPink = Color(0xFF44A0D3);
const kCIOPurple = Color(0xFF3e7eb8);
const kNashPurple = Color(0xFF5927FF);

const kGradientLighterBlue = Color(0xFFD5E6F8);
const kGradientLightBlue = Color(0xFF98C4F3);

const kPendingOrange = Color(0xFFFF9800);

///Ciso colors
const kCISOOrange = Color(0xFFe1751b);
const kCISOLightOrange = Color(0xFFfdc975);
const kCISOTeal = Color(0xFF00a592);
const kCISOPink = Color(0xFFec60b7);
const kCISOBlue = Color(0xFF3cb8ff);
const kCISOYellow = Color(0xFFefc315);
const kCISOPurple = Color(0xFF8458ac);
const kCISOGreenYellow = Color(0xFFd4e001);

///Connected summit colors
const kConnectedGreen = Color(0xFF4C9B46);
const kSkyBlue = Color(0xFF28a2f1);
const kDarkBlue = Color(0xFF174794);
const kDarkerBlue = Color(0xFF002f5e);
const kProfileBlue = Color(0xFF002c59);
const kConnectedOrange = Color(0xFFF79016);
const kConnectedBlue = Color(0xFF44A0D3);
const kConnectedRed = Color(0xFFEC3C3A);


final kCISOToday = DateTime(2025, 11, 19);
final kCISOFirstDay =
    DateTime(kCISOToday.year, kCISOToday.month - 30, kCISOToday.day);
final kCISOLastDay =
    DateTime(kCISOToday.year, kCISOToday.month + 30, kCISOToday.day);

/// The current event's date span. Update these two dates per event — every
/// calendar day in the inclusive range is offered when requesting a meeting.
final DateTime kEventStart = DateTime(2026, 7, 22);
final DateTime kEventEnd = DateTime(2026, 7, 24);

/// Every day the event runs (inclusive), midnight-normalised. Used to populate
/// the meeting-request date picker so a user can book a meeting on any event
/// day, not just today.
List<DateTime> get kEventDays {
  final days = <DateTime>[];
  var day = DateTime(kEventStart.year, kEventStart.month, kEventStart.day);
  final last = DateTime(kEventEnd.year, kEventEnd.month, kEventEnd.day);
  while (!day.isAfter(last)) {
    days.add(day);
    day = day.add(const Duration(days: 1));
  }
  return days;
}

final RegExp emailValidatorRegExp =
    RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
const String kFirstName = "firstName";
const String kLastName = "lastName";
const String kEmail = "email";
const String kPhone = "phoneNumber";
const String kRole = "role";
const String kCompany = "company";
const String kUserID = "userID";
const String kProfileID = "profileID";
const String kIsAdmin = "isAdmin";
const String kSponsorPhone = "sponsorPhone";
const String kDefaultPassword = "DX5iveCIO100";
FirebaseAnalytics analytics = FirebaseAnalytics.instance;


final usersRef = FirebaseFirestore.instance.collection("users");
final notificationsRef = FirebaseFirestore.instance.collection("notifications");

List<Color> predefinedColors = [
  Colors.red,
  Colors.blue,
  Colors.green,
  kPendingOrange,
  kCIOPink,
  // Add more colors as needed
];

verticalSpace({required double height}) {
  return SizedBox(
    height: height,
  );
}

horizontalSpace({required double width}) {
  return SizedBox(
    width: width,
  );
}

primaryButton(
    {required BuildContext context,
    required VoidCallback onPressedFunction,
    required String buttonText}) {
  return SizedBox(
    width: MediaQuery.of(context).size.width * 0.6,
    child: ElevatedButton(
        onPressed: onPressedFunction,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: kPrimaryLightGrey, // Text color
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: kTextColorBlack),
        )),
  );
}

primaryButton2(
    {required BuildContext context,
    required VoidCallback onPressedFunction,
    required String buttonText,required Color backgroundColor}) {
  return SizedBox(
    width: MediaQuery.of(context).size.width * 0.6,
    child: ElevatedButton(
        onPressed: onPressedFunction,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: backgroundColor, // Text color
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
              color: kTextColorBlack),
        )),
  );
}

Widget connectButton({
  required String assetName,
  required String firstName,
  required String lastName,
  required String currentUSerName,
  required String role,
  required String company,
  required String profileid,
  required String email,
  required bool hasDownloadedApp,
  required String requestedByphone,
  required String meetingWithPhone,
  required int userID,
  required BuildContext context,
}) {
  return IntrinsicWidth(
    child: SizedBox(
      height: 35,
      child: primaryButton2(
        backgroundColor: kConnectedBlue,
        context: context,
        onPressedFunction: () {
          PersistentNavBarNavigator.pushNewScreen(
            context,
            screen: IndividualAttendeeScreen(
              assetName: assetName,
              FirstName: firstName,
              LastName: lastName,
              Role: role,
              Company: company,
              profileid: profileid,
              id: userID,
              Bio: '',
              email: email,
              requestedByphone: requestedByphone,
              meetingWithPhone: meetingWithPhone, hasDownloadedApp: hasDownloadedApp,
              currentUserName: currentUSerName,
            ),
            withNavBar: false,
            pageTransitionAnimation: PageTransitionAnimation.slideRight,
          );
        },
        buttonText: "Connect",
      ),
    ),
  );
}


Future checkContainsKey(key, Function keyFunction) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.containsKey(key)) {
    keyFunction();
  }
}

Future<String> getStringPref(key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(key) ?? "";
}

Future<int> getIntPref(key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt(key) ?? 0;
}

Future<bool> getBoolPref(key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(key) ?? false;
}

Future<double> getDoublePref(key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getDouble(key) ?? 0.0;
}

Future<void> setStringPref({required String key, required String value}) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString(key, value);
}

Future<void> setIntPref({required String key, required int value}) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt(key, value);
}

Future<void> setBoolPref({required String key, required bool value}) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool(key, value);
}

Future<void> setDoublePref({required String key, required double value}) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setDouble(key, value);
}

Future<void> clearAllPrefs() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.clear();
}

String convertToAmPm(String time) {
  // Parse the time string
  final DateTime parsedTime = DateFormat('HH:mm:ss').parse(time);
  // Format it to a 12-hour format with AM/PM
  final String formattedTime = DateFormat('h:mm a').format(parsedTime);
  return formattedTime;
}

///TextStyles
///
///

TextStyle kGreyTextStyle({required double fontsiZe}) {
  return TextStyle(
      color: kTextColorGrey, fontSize: fontsiZe, fontWeight: FontWeight.w600);
}

TextStyle kNameTextStyle({required double fontsiZe}) {
  return TextStyle(
      color: kDarkBold, fontSize: fontsiZe, fontWeight: FontWeight.w500);
}

TextStyle kFullAgendaDayTextStyle({required double fontsiZe}) {
  return TextStyle(
      color: kIconDeepBlue, fontSize: fontsiZe, fontWeight: FontWeight.w500);
}
TextStyle kFullAgendaDateTextStyle({required double fontsiZe}) {
  return TextStyle(
      color: kIconDeepBlue, fontSize: fontsiZe, fontWeight: FontWeight.w700);
}

TextStyle kFutureTextStyle({required double fontsiZe}) {
  return TextStyle(
      color: kWhiteColor, fontSize: fontsiZe, fontWeight: FontWeight.w600);
}


