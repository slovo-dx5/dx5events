import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/apigeeregistry/v1.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';

import '../constants.dart';
import '../helpers/analytics_helper.dart';
import '../helpers/helper_functions.dart';

class CIOWidgets {
  // itemWidget({
  //   required BuildContext context,
  //   required String itemName,
  //   required String assetName,
  // }) {
  //   return Container(
  //     height: MediaQuery.of(context).size.height * 0.13,
  //     width: MediaQuery.of(context).size.height * 0.13,
  //     decoration: BoxDecoration(
  //         color: kCIOPink.withOpacity(0.03),
  //         borderRadius: BorderRadius.circular(10)),
  //     padding: const EdgeInsets.all(4),
  //     child: Column(
  //       children: [
  //         SizedBox(
  //             height: MediaQuery.of(context).size.height * 0.07,
  //             width: MediaQuery.of(context).size.height * 0.07,
  //             child: Image.asset(assetName)),
  //         verticalSpace(height: 5),
  //         Text(itemName)
  //       ],
  //     ),
  //   );
  // }

  gradientItemWidget({ required BuildContext context,required Color firstColor, required String analyticsActionName, required Color secondColor,required Widget editIcon,
    required Widget screen,
    required String itemName,}){
      return Column(
        children: [
          GestureDetector(onTap: ()async{
            await Dx5veAnalytics().logdx5veEvent(eventName: analyticsActionName);
            PersistentNavBarNavigator.pushNewScreen(
              context,
              screen: screen,
              withNavBar: false,
              pageTransitionAnimation: PageTransitionAnimation.slideRight,
            );
          },
            child: Container(
              height: MediaQuery.of(context).size.width * 0.18,
              width: MediaQuery.of(context).size.width * 0.18,
              margin: EdgeInsets.only(bottom: 5,top: 15), // Adjust the margin as needed
              decoration: BoxDecoration(
                gradient:  LinearGradient(
                  colors: [
                    firstColor,
                   secondColor // Lighter shade of blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15), // Rounded corners
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15), // Ensure the child matches the container border radius
                child: Container(
                  padding: EdgeInsets.all(5), // Adjust padding as needed
                  child:Stack(alignment: Alignment.center,
                    children: [
                      SizedBox(height: 50,width: 50,child: editIcon,),verticalSpace( height: 5),


                    ],
                  ),
                ),
              ),
            ),
          ),Text(itemName)
        ],
      );

  }

  itemWidget(
      {
    required Widget editIcon,
    required Widget screen,
    required String itemName,
    required BuildContext context,
  }) {

    return GestureDetector(
      onTap: ()async {
        PersistentNavBarNavigator.pushNewScreen(context,
            withNavBar: true,
            screen: screen,
            pageTransitionAnimation: PageTransitionAnimation.cupertino);

      },
      child: SizedBox(
        height: MediaQuery.of(context).size.width * 0.28,
        width: MediaQuery.of(context).size.width * 0.28,
        child: Card(

          child: Stack(alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [SizedBox(height: 50,width: 50,child: editIcon,),verticalSpace( height: 5) ,Text(itemName)],
              ),


            ],
          ),
        ),
      ),
    );
  }

  cioAppBar({required String title}) {
    return AppBar(backgroundColor: kScaffoldBackground,centerTitle: true,
      title:  Text(title,style: TextStyle(color: kTextColorBlackLighter,fontSize: 15,fontWeight: FontWeight.w600),),
      actions:  [Icon(Icons.notification_important_rounded,color: kTextColorBlackLighter,)],
    );
  }

  adminWidget({required String assetPath,required BuildContext context,required Widget screen, required String actionTitle,
    required String actionDescription}){
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(onTap: (){
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: screen,

          withNavBar: false,
          pageTransitionAnimation: PageTransitionAnimation.slideRight,
        );
      },
        child: Card(
          shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(12.0),
            side:  BorderSide(
              color: Colors.red.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Container(padding: EdgeInsets.all(5),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                ),
            width: MediaQuery.of(context).size.width,height: 70,
            child: Row(children: [SizedBox(height:30,width:30,child: Image.asset(assetPath)),
              horizontalSpace(width: 10),

              Column(
              crossAxisAlignment: CrossAxisAlignment.start,mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Text(actionTitle,style: TextStyle(fontWeight: FontWeight.w700,fontSize: 17),),
              Text(actionDescription),
            ],)

          ],),),
        ),
      ),
    );
  }

  clickableWidget({required BuildContext context, required String assetPath, }){
    return GestureDetector(onTap:(){
      openBannerURL();

    },child: Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        height: MediaQuery.of(context).size.height*0.22,width: MediaQuery.of(context).size.width,child: Image.asset(assetPath,fit: BoxFit.contain,), ),
    ));
  }
}
