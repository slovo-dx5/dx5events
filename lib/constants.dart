import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
//const kScreenBlue = Color(0xFF182034);

//Keys

const kKeyRedBG = Color(0xFFff0000);
const kKeyShadowRed = Color(0xFF93261a);
const kLightGrayishOrange = Color(0xFFeae3dc);
const kGrayishOrange = Color(0xFFb4a597);
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

const kPrimaryColor = Color(0xFFa14ea5);
const kGoldColor = Color(0xFFd4af37);
const kScaffoldBackground = Color(0xFFF3F3F8);
const kLightAppbar = Color(0xFFF5F6FA);
Color kPrimaryColorLight = const Color(0xFFa14ea5).withOpacity(0.25);

const kWhiteColor = Colors.white;

const kPrimaryBlueColor = Color(0xFF3297F4);
const kPrimaryLightGrey = Color(0xFFD4D4D4);

const kTextColorBlack = Color(0xFF000000);
Color kTextColorBlackLighter = const Color(0xFF000000).withOpacity(0.75);
const kTextColorGrey = Color(0xFF757575);
const kTextColorNavy = Color(0xFF003665);

const kCIOPink = Color(0xFFa14ea5);
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
const kCISOPurple= Color(0xFF8458ac);
const kCISOGreenYellow = Color(0xFFd4e001);


final kCISOToday = DateTime(2024, 03, 20);
final kCISOFirstDay = DateTime(kCISOToday.year, kCISOToday.month - 2, kCISOToday.day);
final kCISOLastDay = DateTime(kCISOToday.year, kCISOToday.month + 2, kCISOToday.day);







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
const String kDefaultPassword = "DX5iveCIO100";

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
          primary: kPrimaryLightGrey, // Background color
          onPrimary: Colors.white, // Text color
        ),
        child: Text(
          buttonText,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14,color: kTextColorBlack),
        )),
  );
}

connectButton({required String assetName,required String firstName, required String lastName,
  required String role, required String company,
  required String bio, required String profileid, required int userID, required BuildContext context}) {
  return SizedBox(height: 30,
    child: ElevatedButton(
      onPressed: () {
        // PersistentNavBarNavigator.pushNewScreen(
        //   context,
        //   screen: IndividualAttendeeScreen(
        //     assetName: assetName,
        //     FirstName: firstName,
        //     LastName: lastName,
        //     Role: role,
        //     Company: company,
        //     Bio: bio,
        //     profileid: profileid, id: userID,
        //   ),
        //   withNavBar: false,
        //   pageTransitionAnimation: PageTransitionAnimation.slideRight,
        // );
      },
      style: ButtonStyle(
          backgroundColor: const MaterialStatePropertyAll<Color>(kCIOPink),
          textStyle: const MaterialStatePropertyAll<TextStyle>(TextStyle(fontWeight: FontWeight.w200, fontSize: 13,color: Colors.white)),

          shape: MaterialStatePropertyAll<RoundedRectangleBorder>(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7.0)

          ))
      ),

      child: const Text("Connect"),
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
  return  prefs.getString(key) ?? "";
}

Future<int> getIntPref(key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return  prefs.getInt(key) ?? 0;
}

Future<bool> getBoolPref(key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return  prefs.getBool(key) ?? false;
}

Future<double> getDoublePref(key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return  prefs.getDouble(key) ?? 0.0;
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

TextStyle kGreyTextStyle({required double fontsiZe}

    ) {
  return TextStyle(color: kTextColorGrey, fontSize: fontsiZe, fontWeight: FontWeight.w600);
}TextStyle kNameTextStyle({required double fontsiZe}

    ) {
  return TextStyle(color: kDarkBold, fontSize: fontsiZe, fontWeight: FontWeight.w500);
}