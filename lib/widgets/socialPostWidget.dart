import 'dart:math';

import 'package:dx5veevents/dioServices/dioFetchService.dart';
import 'package:dx5veevents/dioServices/dioPostService.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' as intl;
import '../helpers/helper_functions.dart';
import '../models/social_post_model.dart';

import '../constants.dart';
import '../screens/dx5ve_social/social_feed.dart';

class SocialMediaPost extends StatefulWidget {
  String userName;
  String currentUsername;
  String imageUrl;
  String dateString;
  int likes;
  int postID;
  int currentUserID;
  final List<CommentModel> comments;
  String description;
   SocialMediaPost({super.key,required this.likes,

     required this.currentUserID, required this.postID,required this.currentUsername,
     required this.dateString,required this.comments, required this.userName,required this.description,
   required this.imageUrl});

  @override
  State<SocialMediaPost> createState() => _SocialMediaPostState();
}

class _SocialMediaPostState extends State<SocialMediaPost> {
  bool _isExpanded=false;
  bool _showReadMore = false;
  Random random = Random();
  final int randomIndex = Random().nextInt(predefinedColors.length);
  late Color randomBackgroundColor;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    setState(() {
      randomBackgroundColor= predefinedColors[randomIndex];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTextOverflow(contentText: widget.description));
  }

  addLikeToPost({required int postId, required int userID, required LikesModel newLike}) async {
    try {
      // Step 1: Fetch the post to get existing comments
      final response = await DioFetchService().fetchSinglePost(postId: postId);
      print("got post details");

      if (response.statusCode == 200) {
        // Step 2: Parse the existing comments
        var existingLikes = <LikesModel>[];

        // Access the nested 'data' key first
        final postData = response.data['data'];

        // Check if 'Comments' exists and is a list
        if (postData != null && postData['likes'] is List) {
          existingLikes = List<LikesModel>.from(
            (postData['likes'] as List<dynamic>).map((data) => LikesModel.fromJson(data)),
          );
        }
        if(existingLikes.any((like) => like.likerId == userID)){
          Fluttertoast.showToast(msg: "You already liked this post");
          return;
        }else{
          print("liking post");

          existingLikes.add(newLike);
          // Step 4: Send PATCH request with updated comments list
          final likeBody = {
            "likes": existingLikes.map((like) => like.toJson()).toList(),
          };
         final likeResponse= await DioPostService().patchComments(
            body: likeBody,
            postID: postId,
          );
          await UserPointsService().
          createOrUpdateUserPoints(userId: widget.currentUserID,actionId: 13);
          Fluttertoast.showToast(msg: "Post liked successfully");
         print("Like response is ${likeResponse.data}");

        }

        // Step 3: Add the new comment to the list



      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error:Check your internet and retry");
    }
  }

 


  String formatDate(String dateStr) {
    final DateTime dateTime = DateTime.parse(dateStr);
    return intl.DateFormat('dd MMM yyyy').format(dateTime);
  }

  String getInitials(String fullName) {
    return fullName
        .split(' ')                 // Split the string by spaces
        .where((word) => word.isNotEmpty) // Filter out any empty strings (in case of multiple spaces)
        .map((word) => word[0])      // Take the first letter of each word
        .join()                      // Join them back together
        .toUpperCase();              // Convert to uppercase (optional)
  }


  void _checkTextOverflow({required String contentText}) {
    // Check if the text exceeds three lines
    final textSpan = TextSpan(
      text: contentText,
       style: const TextStyle(fontSize: 14),
    );

    final textPainter = TextPainter(
      text: textSpan,
      maxLines: 3,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 48); // Adjust width

    setState(() {
      _showReadMore = textPainter.didExceedMaxLines;
    });
  }

  void _showCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "Comments",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const Divider(),

              // List of comments
              Expanded(
                child: ListView.builder(
                  itemCount: widget.comments.length, // Replace with actual comments count
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Text('U'), // Replace with actual user's initials or image
                      ),
                      title: Text('User $index'), // Replace with actual username
                      subtitle: const Text('This is a comment'), // Replace with actual comment text
                    );
                  },
                ),
              ),

              // TextField for new comment
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Add a comment...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color:kPrimaryColor),
                      onPressed: () {
                        // Implement send comment functionality here
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        //color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),

            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
      CircleAvatar(backgroundColor:randomBackgroundColor,
        radius: 25,
        child: Center(child: Text(getInitials(widget.userName),
          style:  const TextStyle(color: Colors.white,fontSize: 20),)),),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                   Text(
                    formatDate(widget.dateString),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              // Check if contentText exceeds three lines
              final textPainter = TextPainter(
                text: TextSpan(text: widget.description, style: const TextStyle(fontSize: 14)),
                maxLines: _isExpanded ? null : 3,
                textDirection: TextDirection.ltr,
              )..layout(maxWidth: constraints.maxWidth);

              final isOverflowing = textPainter.didExceedMaxLines;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.description,
                    maxLines: _isExpanded ? null : 3,
                    overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                  if (_showReadMore)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Text(
                        _isExpanded ? 'Show Less' : 'Read More',
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // Post content

          const SizedBox(height: 5),

          SizedBox(height: 12),

          // Image
          if(widget.imageUrl!="no image")ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              "https://subscriptions.cioafrica.co/assets/${widget.imageUrl}",
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),

          // Likes and Comments
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                      onTap: ()async{
                       await addLikeToPost(postId: widget.postID,
                           userID: widget.currentUserID, newLike: LikesModel(
                           // ID of the user making the comment
                           postId: widget.postID, // ID of the post being commented on
                   likerId: widget.currentUserID, // Name of the user making the comment
                         ),);
                      },
                      child: const Icon(Icons.favorite, color: kPrimaryColor, size: 25)),
                  const SizedBox(width: 4),
                  Text(widget.likes.toString()),
                ],
              ),
               GestureDetector(onTap: () {
                 showModalBottomSheet(
                   backgroundColor: kGradientLighterBlue,
                   context: context,
                   isScrollControlled: true,
                   builder: (_) {
                     return Container(
                       height: MediaQuery.of(context).size.height * 0.85,
                       child: CommentsBottomSheet(comments: widget.comments, postId: widget.postID,
                         currentUserID: widget.currentUserID, currentUserName: widget.currentUsername,),
                     );
                   },
                 );
               },
                 child: Row(
                  children: [
                    const Icon(Icons.comment, color: Colors.grey, size: 20),
                    const SizedBox(width: 4),
                    Text(widget.comments.length.toString()),
                  ],
              ),
               ),
            ],
          ),
        ],
      ),
    );
  }
}
class CommentsBottomSheet extends StatefulWidget {
  final List<CommentModel> comments;
  int postId;
  int currentUserID;
  String currentUserName;

   CommentsBottomSheet({super.key, required this.comments,
     required this.currentUserID,required this.currentUserName,
     required this.postId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  TextEditingController commentController=TextEditingController();

  addCommentToPost({required int postId, required CommentModel newComment}) async {
    try {
      // Step 1: Fetch the post to get existing comments
      final response = await DioFetchService().fetchSinglePost(postId: postId);

      if (response.statusCode == 200) {
        // Step 2: Parse the existing comments
        var existingComments = <CommentModel>[];

          // Access the nested 'data' key first
          final postData = response.data['data'];

          // Check if 'Comments' exists and is a list
          if (postData != null && postData['Comments'] is List) {
            existingComments = List<CommentModel>.from(
              (postData['Comments'] as List<dynamic>).map((data) => CommentModel.fromJson(data)),
            );
          }


        // Step 3: Add the new comment to the list
        existingComments.add(newComment);

        // Step 4: Send PATCH request with updated comments list
        final commentBody = {
          "Comments": existingComments.map((comment) => comment.toJson()).toList(),
        };
        await DioPostService().patchComments(
          body: commentBody,
          postID: postId,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error:Check your internet and retry");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: Padding(
            padding: EdgeInsets.only(
              top: 25,

              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
               widget.comments.isEmpty?
               Center(child: Column(
                 children: [
                   SizedBox(height:100,width:100,child: Image.asset("assets/icons/no_comment.png")),
                   const Text("No comments yet. Leave one",style: TextStyle(color:kScreenDark ,fontSize: 15),),
                   verticalSpace(height: 20)
                 ],
               ),): Expanded(
                  child: ListView.builder(
                    itemCount: widget.comments.length,
                    itemBuilder: (context, index) {
                      final comment = widget.comments.reversed.toList()[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(backgroundColor:kGoldColor,
                          radius: 25,
                          child: Text(getInitials(comment.commenterName),
                            style:  const TextStyle(color: Colors.white,fontSize: 20),),),
                        horizontalSpace(width: 10),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Card(
                            color: kRightBubble.withOpacity(0.7),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.commenterName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: kToggleDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment.comment,
                                    style: const TextStyle(fontSize: 12, color: kToggleDark,fontWeight: FontWeight.w200),
                                    maxLines: 5, // Set a maximum number of lines
                                    overflow: TextOverflow.ellipsis, // Show ellipsis if overflow
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )

                        ],),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      SizedBox(width: MediaQuery.of(context).size.width*0.75,
                        child: TextFormField(
                          keyboardType: TextInputType.multiline,
                         // controller: _postTextController,
                          maxLines: null,
                          controller: commentController,
                          decoration: const InputDecoration(
                            labelText: 'Add a comment...',
                            border: OutlineInputBorder(),
                          ),

                        ),
                      ),
                      IconButton(onPressed: ()async{
                       if(commentController.text.isNotEmpty ){
                         await addCommentToPost(postId: widget.postId,
                           newComment: CommentModel(
                           comment: commentController.text,
                           commenterId: widget.currentUserID, // ID of the user making the comment
                           postId: widget.postId, // ID of the post being commented on
                           commenterName: widget.currentUserName, // Name of the user making the comment
                         ),

                         );

                         await UserPointsService().
                         createOrUpdateUserPoints(userId: widget.currentUserID,actionId: 12);

                         Fluttertoast.showToast(msg: "Comment submitted");
                         commentController.clear();
                         Navigator.pushReplacement(
                             context,
                             MaterialPageRoute(
                                 builder: (BuildContext context) => SocialFeed()));
                         await DioFetchService().fetchSocialPosts();
                         setState(() {

                         });

                       }else{
                         Fluttertoast.showToast(msg: "Cannot send empty text");
                       }
                      }, icon: const Icon(Icons.send,size: 40,color: kCIOPink,))
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
