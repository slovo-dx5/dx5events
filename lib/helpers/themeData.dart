
import 'package:flutter/material.dart';

import '../constants.dart';


///Dark theme
ThemeData darkTheme =
ThemeData(

    scaffoldBackgroundColor: kDarkScaffold,
    backgroundColor:kToggleDark,

    //For Keys
    disabledColor: kLightGrayishOrange,
    dividerColor:kGrayishOrange ,

    cardColor: kDarkCard,
    fontFamily: 'Poppins',


    ///Works for text fields
    inputDecorationTheme: InputDecorationTheme(
      labelStyle:  TextStyle(color: kWhiteColor.withOpacity(0.5)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: kGrayishOrange.withOpacity(0.5)), // Specify your color here
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: kPrimaryColor), // Specify your focused color here
        ),
        disabledBorder:const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.pink), // Specify your focused color here
        ) ,
        filled: true,
        fillColor: kDarkFill,
        outlineBorder: const BorderSide(color: kPrimaryColor),
        border: OutlineInputBorder(
         // borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(8.0),
        )),



    textTheme:   const TextTheme(
      bodyLarge: TextStyle(
          color: kWhiteText,
          fontSize: 15,
          fontWeight: FontWeight.w500

      ),
      bodyMedium: TextStyle(
        color: kWhiteText,
        fontSize: 12,
        // fontWeight: FontWeight.bold

      ),

      bodySmall: TextStyle(
          color: kWhiteText,
          fontSize: 15,
          fontWeight: FontWeight.bold

      ),
      titleLarge:TextStyle(
          color: kWhiteText,
          fontSize: 32,
          fontWeight: FontWeight.bold

      ),
      titleMedium: TextStyle(color: kWhiteText,)
    ),



    checkboxTheme: const CheckboxThemeData(
      fillColor: MaterialStatePropertyAll<Color>(kScreenGray),
    ),

    listTileTheme: const ListTileThemeData(
        textColor: kScreenGray
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
            backgroundColor: const MaterialStatePropertyAll<Color>(kPrimaryColor),
            textStyle: const MaterialStatePropertyAll<TextStyle>(TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
            shape: MaterialStatePropertyAll<RoundedRectangleBorder>(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0)

            ))
        )

    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kPrimaryColor,
    ),
    iconTheme: const IconThemeData(color: kPrimaryColor),
    iconButtonTheme: const IconButtonThemeData(style: ButtonStyle(
      backgroundColor: MaterialStatePropertyAll<Color>(kPrimaryColor),

    )),

    switchTheme: SwitchThemeData(
      thumbColor:  MaterialStateProperty.all(kPrimaryColor),
      trackColor:  MaterialStateProperty.all(kPrimaryLight),),

    appBarTheme: const AppBarTheme(
        iconTheme: IconThemeData(color: kPrimaryColor),
        backgroundColor: kDarkAppbar,
        elevation: 0.0,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)

    ),

    bottomAppBarTheme: const BottomAppBarTheme(color: kScreenDark),


);

///Light theme
ThemeData lightTheme =
ThemeData(

    scaffoldBackgroundColor: kScaffoldColor,
    backgroundColor:kToggleLight ,
    bottomAppBarColor: kScreenGray,

    //For Keys
    disabledColor: kLightDisabledColor,
    dividerColor:kLightNormalText ,

    //For equal sign
    // highlightColor: kKeyOrangeBG,
    // canvasColor: kKeyOrangeShadow,

    //For Del and reset buttons
    // focusColor: kKeyBackgroundCyan,
    cardColor: kLightCardColor,
    fontFamily: 'Poppins',


    textTheme:  const TextTheme(
      bodyLarge: TextStyle(
          color: kScreenDark,
          fontSize: 15,
          fontWeight: FontWeight.w500

      ),
      bodyMedium: TextStyle(
        color: kLightNormalText,
        fontSize: 12,
        //fontWeight: FontWeight.bold

      ),

      bodySmall: TextStyle(
          color: kWhiteText,
          fontSize: 15,
          fontWeight: FontWeight.bold

      ),
      titleLarge:TextStyle(
          color: kDarkGrayishYellow,
          fontSize: 32,
          fontWeight: FontWeight.bold

      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      // Sets the default underline color for all `TextField`s
      // (replace `Colors.green` with your desired color)
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: kPrimaryColor),
      ),
      // Sets the default underline color when focused for all `TextField`s
      // (replace `Colors.red` with your desired color)
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: kPrimaryColor),
      ),
    ),

    checkboxTheme: const CheckboxThemeData(
      fillColor: MaterialStatePropertyAll<Color>(kToggleDark),
    ),

    listTileTheme: const ListTileThemeData(
        textColor: kToggleDark
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
            backgroundColor: const MaterialStatePropertyAll<Color>(kPrimaryColor),
            textStyle: const MaterialStatePropertyAll<TextStyle>(TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
            shape: MaterialStatePropertyAll<RoundedRectangleBorder>(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0)

            ))
        )

    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kPrimaryColor,
    ),
    iconTheme: const IconThemeData(color: kPrimaryColor),
    iconButtonTheme: const IconButtonThemeData(style: ButtonStyle(
      backgroundColor: MaterialStatePropertyAll<Color>(kPrimaryColor),

    )),

    switchTheme: SwitchThemeData(
      thumbColor:  MaterialStateProperty.all(kPrimaryColor),
      trackColor:  MaterialStateProperty.all(kPrimaryColorLight),


    ),



    appBarTheme:  AppBarTheme(
        iconTheme: IconThemeData(color: kPrimaryColor),
        backgroundColor: kLightAppbar,
        elevation: 0.0,
        titleTextStyle: TextStyle(color: kTextColorBlackLighter, fontSize: 20, fontWeight: FontWeight.bold)

    )


);

