import 'package:dx5veevents/dioServices/dioPostService.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../constants.dart';

class RatingDialog extends StatefulWidget {

  int attendeeID;
  String speakerName;
  String sessionTitle;
  int eventId;
   RatingDialog({required this.attendeeID,required this.eventId, required this.sessionTitle, required this.speakerName,super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {


    int _SessionRating = 0;
    int _SpeakerRating = 0;
    final TextEditingController _sessionCommentController = TextEditingController();
    final TextEditingController _speakerCommentController = TextEditingController();

    @override
    Widget build(BuildContext context) {
      return AlertDialog(
        backgroundColor: kToggleLight,

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('SESSION RATING', style: TextStyle(fontSize: 15,color: kIconPurple, fontWeight: FontWeight.bold),),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _SessionRating ? Icons.star : Icons.star_border,
                    color: index < _SessionRating ? kIconPurple : Colors.grey,size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _SessionRating = index + 1;
                    });
                  },
                );
              }),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _sessionCommentController,
              decoration: const InputDecoration(
                hintText: 'Your thoughts on this session',
                hintStyle: TextStyle(color:kToggleLight,fontSize: 11 ),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            const Text('SPEAKER RATING', style: TextStyle(fontSize: 15,color: kIconPurple, fontWeight: FontWeight.bold),),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _SpeakerRating ? Icons.star : Icons.star_border,
                    color: index < _SpeakerRating ? kIconPurple : Colors.grey,size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _SpeakerRating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _speakerCommentController,
              decoration: const InputDecoration(
                hintText: 'Comments on the speaker',
                hintStyle:TextStyle(color:kToggleLight,fontSize: 11 ),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [

          TextButton(
            child: Text('Submit',style: TextStyle(color:kIconPurple ),),
            onPressed: ()async {
              try{
                DioPostService().postSessionRating( context: context, attendeeID: widget.attendeeID,
                    speakerRating: _SpeakerRating, sessionRating: _SessionRating,
                    sessionComment: _sessionCommentController.text, speakerName: widget.speakerName, speakerComment: _speakerCommentController.text, sessionTitle: widget.sessionTitle);
                Fluttertoast.showToast(backgroundColor:kLogoutRed,msg: "Your response has been recorded");
                Navigator.of(context).pop();

              }catch(e){}
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    }
  }

