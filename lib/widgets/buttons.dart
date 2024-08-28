import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';

import '../constants.dart';
import '../helpers/helper_functions.dart';
import '../screens/proposeToSpeakPage.dart';
import '../screens/sponsorEventScreen.dart';

buyTicketButton({required BuildContext context, required String ticketSlug}) {
  return SizedBox(
    height: 50,
    width: MediaQuery.of(context).size.width ,
    child: ElevatedButton(
        onPressed: () {
          openTicketURL(slug: ticketSlug);
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: kPrimaryColor, // Text color
        ),
        child: const Text(
          "BUY TICKET",
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: kTextColorBlack),
        )),
  );
}

proposeToSpeakButton({required BuildContext context}) {
  return GestureDetector(onTap: (){
    PersistentNavBarNavigator.pushNewScreen(
      context,
      screen: ProposeToSpeakPage(eventID: '8', eventName: 'SMART BANKING',

      ),
      withNavBar: false,
      pageTransitionAnimation: PageTransitionAnimation.slideRight,
    );
  },
    child: Container(
      height: 50,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: kWhiteColor.withOpacity(0.5))),child: Center(child:  Text("PROPOSE TO SPEAK",style: kFutureTextStyle(fontsiZe: 14),)),
    ),
  );
}
sponsorEventButton({required BuildContext context}) {
  return GestureDetector(onTap: (){
    PersistentNavBarNavigator.pushNewScreen(
      context,
      screen: const SponsorEventScreen(

      ),
      withNavBar: false,
      pageTransitionAnimation: PageTransitionAnimation.slideRight,
    );
  },
    child: Container(
      height: 50,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),color: kIconPink
       ),child:  Center(child: Text("SPONSOR",style: kFutureTextStyle(fontsiZe: 12),)),
    ),
  );
}
