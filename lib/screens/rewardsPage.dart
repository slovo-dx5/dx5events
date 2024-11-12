import 'dart:convert';

import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dioServices/dioFetchService.dart';
import '../helpers/helper_widgets.dart';
import '../models/eventAttendeesModel.dart';
import '../providers/themeProvider.dart';
import '../widgets/pointsWidget.dart';

class RewardsPage extends StatefulWidget {
  //String eventID;
   RewardsPage({
     //required this.eventID,

     super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  List<dynamic> actions = [];
  List<dynamic> userIDs = [];
  List<EventAttendeeModel>? leaderboardList;
  Map<int, dynamic> userPointsMap = {};

  @override
  void initState() {
    super.initState();
    fetchActionsAndUserPoints();

    fetchUserDetails().then((value) {
      setState(() {
        leaderboardList=value;
      });

    });
  }

  // Method to fetch and save all user IDs to a list
  Future<void> getAllUserIds() async {
    try {
      final actionResponse = await DioFetchService().getAllUserPoints();

      // Parse the response and extract user IDs
      if (actionResponse.statusCode == 200) {
        final data = actionResponse.data['data'];

        // Clear the list first if needed
        userIDs.clear();

        // Loop through the user_points and add user IDs to the list
        for (var item in data) {
          int userId = item['user_id'];

          if (!userIDs.contains(userId)) {
            userIDs.add(userId);

          }
        }

        print("Fetched user IDs: $userIDs");
      } else  {
        print("Failed to fetch user points data.");
      }
    } catch (error) {
      print("Error fetching user IDs: $error");
    }
  }


  fetchActionsAndUserPoints() async {
    try {
      // Fetch actions
      final actionResponse = await DioFetchService().getAllActions();

      if (actionResponse.statusCode == 200) {
        setState(() {
          actions = actionResponse.data['data'];
        });
      } else {
        print('Failed to load actions.');
      }

      // Fetch user points
      final userPointsResponse =
          await DioFetchService().getUserPointsResponse(userId: 4897);

      if (userPointsResponse.statusCode == 200) {
        List<dynamic> userPoints = userPointsResponse.data['data'];

        // Create a map with action_id as the key for quick lookup
        setState(() {
          userPointsMap = {
            for (var point in userPoints) point['action_id']: point
          };
        });
      } else {
        print('Failed to load user points.');
      }
    } catch (error) {
      print('Error fetching actions and user points: $error');
    }
  }

  // Function to determine if an action is complete
  bool isActionComplete(int actionId, int requiredOccurrences) {
    if (userPointsMap.containsKey(actionId)) {
      final int occurrences = userPointsMap[actionId]['occurences'];
      return occurrences >= requiredOccurrences;
    }
    return false;
  }

  // Function to get the current number of occurrences or default to 0
  int getCurrentOccurrences(int actionId) {
    if (userPointsMap.containsKey(actionId)) {
      return userPointsMap[actionId]['occurences'];
    }
    return 0; // Default to 0 if no data for this action
  }

  Future<List<EventAttendeeModel>> fetchUserDetails() async {
    List<EventAttendeeModel> tempList = [];
    await getAllUserIds();

    // Loop through all user IDs
    for (var userID in userIDs) {
      var response = await DioFetchService().fetchSingleAttendeeForEvent(
        id: userID,
        eventID: 21, // Replace with your actual event ID
      );

      if (response.statusCode == 200) {
        var data = response.data["data"];

        // Check if `data` is a list or a map
        if (data is List) {
          for (var userJson in data) {
            tempList.add(EventAttendeeModel.fromJson(userJson));
          }// Add all if it's a list
        } else if (data is Map) {
          tempList.add(EventAttendeeModel.fromJson(Map<String, dynamic>.from(data)));        }
      } else {
        print("Error fetching user $userID details: ${response.statusCode}");
      }
    }

// Fetch and add total points for each attendee
    for (var attendee in tempList) {
      int totalPoints = await fetchTotalPointsForUser(attendee.attendeeId);
      attendee.totalPoints = totalPoints; // Add the points to the model
      print("attendee ${attendee.firstName} poitns are $totalPoints");
    }

    // Sort attendees by total points in descending order
    tempList.sort((a, b) => (b.totalPoints ?? 0).compareTo(a.totalPoints ?? 0));
    print("Attendees ordered by total points: ${tempList.map((e) => e.totalPoints).toList()}");



    // Return the list of CISOAttendeeModel
    return tempList;
  }

  Future<int> fetchTotalPointsForUser(int userId) async {
    try {
      final response = await DioFetchService().fetchUserPoints(userID: userId);

      if (response.statusCode == 200) {
        final data = response.data['data'];
        int totalPoints = 0;

        // Loop through all the user's points and sum them
        for (var item in data) {
          var pointsAwarded = item['points_awarded'];

          // Ensure points_awarded is a number before adding to totalPoints
          if (pointsAwarded is num) {
            totalPoints += pointsAwarded.toInt();
          } else {
            print("Warning: points_awarded is not a number: $pointsAwarded");
          }
        }

        print("Total points are $totalPoints");
        return totalPoints;
      } else {
        throw Exception("Failed to fetch points for user $userId");
      }
    } catch (error) {
      print("Error fetching total points for user $userId: $error");
      return 0; // Return 0 points if there's an error
    }
  }





  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return

  SafeArea(
    child: Scaffold(
      appBar: AppBar(title: Text("Rewards"),leading: IconButton(onPressed: (){Navigator.of(context).pop();}, icon: Icon(Icons.arrow_back),color: kCIOPink,),
      ),
      body: SingleChildScrollView(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                tabs: const [
                  Tab(text: "Pending"), // Tab 1
                  Tab(text: "Leaderboard"), // Tab 2
                ],
                labelColor: kPrimaryColor,
                indicatorColor: kPrimaryLight,
                unselectedLabelColor: themeProvider.themeMode == ThemeModeOptions.light
                    ? kScreenDark
                    : kDarkBold,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height,
                child: TabBarView(
                  children: [
                    ///Pending actions
                    actions.isEmpty
                        ? Center(child: CircularProgressIndicator())
                        : Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/backgrounds/statue.png', // Replace with your image asset
                            fit: BoxFit
                                .cover, // Ensures the image covers the entire background
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            color: Colors.black
                                .withOpacity(0.8), // Adjust the opacity here
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 100.0),
                          child: ListView.builder(
                            itemCount: actions.length,
                            itemBuilder: (context, index) {
                              final action = actions[index];
                              final actionId = action['id'];
                              final actionName = action['action_name'];
                              final screenName = action['screen_name'];
                              final actionPoints = action['action_points'];
                              final actionDescription = action['action_description'];
                              final requiredOccurrences = action['required_occurrence'];
                              final actionURL = action['action_url'];

                              // Check if the action is complete based on occurrences
                              final bool isComplete =
                              isActionComplete(actionId, requiredOccurrences);

                              // Get the user's current occurrences or default to 0
                              final int currentOccurrences =
                              getCurrentOccurrences(actionId);

                              return Column(children: [verticalSpace(height: 5),
                                GamificationSystem().userPointsWidget(context: context,
                                    currentProgress:currentOccurrences,
                                    requiredProgress: requiredOccurrences,
                                    pointsCarried: actionPoints,
                                    actionDescription: actionDescription,
                                    actionName: actionName,
                                    urlString: actionURL, screenName: screenName),

                                verticalSpace(height: 5)],);
                            },
                          ),
                        ),
                      ],
                    ),

                    ///Leaderboard
                    Column(
                      children: [
                        Expanded(
                          child:Padding(
                            padding: const EdgeInsets.only(bottom: 40.0),
                            child: ListView.builder(
                              itemCount: leaderboardList?.length ?? 0, // Safely handle null or empty leaderboardList
                              itemBuilder: (context, index) {
                                if (leaderboardList == null || index >= leaderboardList!.length) {
                                  return const SizedBox(); // Return an empty widget if index is out of bounds
                                }

                                final user = leaderboardList![index];

                                // Determine the color for the numbered label
                                Color labelColor;
                                String labelText;

                                // Assign color based on the index
                                switch (index) {
                                  case 0: // First place
                                    labelColor = Colors.amber; // Gold
                                    labelText = "1st";
                                    break;
                                  case 1: // Second place
                                    labelColor = Colors.grey; // Silver
                                    labelText = "2nd";
                                    break;
                                  case 2: // Third place
                                    labelColor = Color(0xFFA52A2A); // Bronze (or any custom color)
                                    labelText = "3rd";
                                    break;
                                  default: // Default color for the rest
                                    labelColor = Colors.black; // Change as needed
                                    labelText = "${index + 1}"; // Regular numbering
                                    break;
                                }

                                return Row(
                                  children: [
                                    // Number label
                                    Container(
                                      padding: EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: labelColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        labelText,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8), // Space between label and user widget
                                    Expanded(
                                      child: leaderBoardWidget(
                                        assetName: "assetName",
                                        context: context,
                                        firstName: user.firstName ?? 'N/A', // Safely handle null values
                                        lastName: user.lastName ?? 'N/A',  // Safely handle null values
                                        role: user.role ?? 'Unknown Role',  // Safely handle null values
                                        company: user.company ?? 'Unknown Company',  // Safely handle null values
                                        profileid: user.profilePhoto ?? 'default_profile.png', // Fallback for null photo
                                        userID: user.id,
                                        points: user.totalPoints ?? 0,  // Default to 0 if points are null
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          )


                        ),
                      ],
                    )

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    
    ),
  );
  }
}
