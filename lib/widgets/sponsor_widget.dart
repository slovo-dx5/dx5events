import 'package:flutter/material.dart';

import 'cio_bottomsheets.dart';
sponsorWidget({required BuildContext context ,required String sponsorName,required String sponsorAsset,required String sponsorBio,required String degree,required String sponsorURL}) {
  return
    GestureDetector(onTap: (){
      defaultScrollableBottomSheet(context, sponsorName,
          SponsorBottomSheet(SponsorImage: sponsorAsset, SponsorAbout: sponsorBio, SponsorName: sponsorName, SponsorURL: sponsorURL,));
    },child: Opacity(opacity: 0.9,
      child: Container(padding: EdgeInsets.all(8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        height: 160,
        width: MediaQuery.of(context).size.width,
        child: Column(mainAxisSize: MainAxisSize.min,mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(degree,style: const TextStyle(color: Colors.black54,fontWeight: FontWeight.w600),),
            Container(height: 120,width: 250,
              child: Image.network(
                sponsorAsset,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    ),);
}

exhibitorWidget({required BuildContext context ,required String sponsorName,required String sponsorAsset,required String sponsorBio,required String sponsorURL}) {
  return
    GestureDetector(onTap: (){
      defaultScrollableBottomSheet(context, sponsorName, SponsorBottomSheet(SponsorImage: sponsorAsset, SponsorAbout: sponsorBio, SponsorName: sponsorName, SponsorURL: sponsorURL,));
    },child: Container(padding: EdgeInsets.all(8),
      decoration: BoxDecoration(color:Colors.white,borderRadius: BorderRadius.circular(10)),
      height: 75,
      width: MediaQuery.of(context).size.width*0.4,
      child: Column(mainAxisSize: MainAxisSize.min,mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: Image.asset(
              sponsorAsset,
              // fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    ),);
}
vmsybWidget({required BuildContext context ,required String sponsorName,required String sponsorAsset,required String sponsorBio,required String degree, required String sponsorURL}) {
  return
    GestureDetector(onTap: (){
      defaultScrollableBottomSheet(context, sponsorName, SponsorBottomSheet(SponsorImage: sponsorAsset, SponsorAbout: sponsorBio, SponsorName: sponsorName, SponsorURL: sponsorURL,));
    },child: Container(padding: EdgeInsets.all(8),
      decoration: BoxDecoration(color:Colors.white,borderRadius: BorderRadius.circular(10)),
      height: 100,
      width: MediaQuery.of(context).size.width*0.906,
      child: Column(mainAxisSize: MainAxisSize.min,mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(degree,style: TextStyle(color: Colors.black54,fontWeight: FontWeight.w600),),
          Flexible(
            child: Image.asset(
              sponsorAsset,
              // fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    ),);
}
