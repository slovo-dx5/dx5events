import 'package:dx5veevents/constants.dart';
import 'package:dx5veevents/dioServices/dioFetchService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:googleapis/admob/v1.dart';

import '../../models/social_post_model.dart';
import '../../widgets/profile_initials_widget.dart';
import '../../widgets/socialPostWidget.dart';
import 'createPostScreen.dart';

class SocialFeed extends StatefulWidget {
  const SocialFeed({super.key});

  @override
  State<SocialFeed> createState() => _SocialFeedState();
}

class _SocialFeedState extends State<SocialFeed> {
  List <PostData>_futurePosts=[];
  bool isFetchingPosts=false;
  String ?firstName;
  String ?lastName;
  int? currentUserID;

  @override
  void initState() {
    getUserDetails();
    super.initState();
    fetchSocialPosts();
  }


  fetchSocialPosts() async {
    setState(() {
      isFetchingPosts = true;
    });

    final response = await DioFetchService().fetchSocialPosts();

    if (response.statusCode == 200) {
      final rawData = response.data['data'];

      setState(() {
        // Map the JSON response to a list of PostData
        _futurePosts = List<PostData>.from(
          rawData.map((postJson) => PostData.fromJson(postJson)),
        );
        print("Posts are ${_futurePosts.first}");
        isFetchingPosts = false;
      });
    } else {
      throw Exception('Failed to load posts');
    }
  }


  Future<void> _openCreatePostScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );
  }
  getUserDetails()async{
    getStringPref(kFirstName).then((value) {
      setState(() {
        firstName=value;
        print("firt name is $firstName");
      });
    });getIntPref(kUserID).then((value) {
      setState(() {
        currentUserID=value;
        print("useri d name is $currentUserID");
      });
    });
    getStringPref(kLastName).then((value) {

      if(value==""){
        setState(() {
          lastName=".";
        });
      }else{
        setState(() {
          lastName=value;
          print("last name is $lastName");
        });
      }

    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true,
        leading: IconButton(onPressed: (){Navigator.of(context).pop();}, icon: Icon(Icons.arrow_back),color: kCIOPink,),
        automaticallyImplyLeading: true,
        title: const Text("Social Feed"),
      ),
      body: Column(
        children: [
          Row(
            children: [
              ProfileInitials(
                circleRadius: 25, fontSize: 25,
              ),horizontalSpace(width: 5),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => _openCreatePostScreen(),
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Say something',
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 20.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: Visibility(
                visible: isFetchingPosts==false,
                replacement: const Center(child: SpinKitFadingCircle(size: 100,color: kPrimaryColor,)),
                child: ListView.builder( itemCount: _futurePosts.length,
                  itemBuilder: (context, index) {
                    final post = _futurePosts.reversed.toList()[index];
                    return SocialMediaPost(
                      userName: post.userName,
                      description: post.postDescription,
                      imageUrl: post.pictureLink, likes: post.likes?.length??0,
                      comments: post.comments??[], dateString: post.dateCreated,
                      currentUserID: currentUserID!, postID: post.id,
                      currentUsername: "$firstName $lastName", );
                  },
                )),
          )
        ],
      ),
    );
  }
}
