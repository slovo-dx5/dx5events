import 'dart:convert';

import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dioServices/dioFetchService.dart';
import '../providers/themeProvider.dart';
import '../widgets/pointsWidget.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  List<dynamic> actions = [];
  Map<int, dynamic> userPointsMap = {};

  @override
  void initState() {
    super.initState();
    fetchActionsAndUserPoints();
  }


   fetchActionsAndUserPoints() async {
    try {
      // Fetch actions
      final actionResponse = await DioFetchService().getAllActions();

      if (actionResponse.statusCode == 200) {
        setState(() {
          actions = actionResponse.data['data'];
          print("first action ${actions.first["required_occurence"]}");
        });
      } else {
        print('Failed to load actions.');
      }

      // Fetch user points
      final userPointsResponse =
      await DioFetchService().getUserPointsResponse( userId: 625);



      if (userPointsResponse.statusCode == 200) {
        List<dynamic> userPoints = userPointsResponse.data['data'];

        // Create a map with action_id as the key for quick lookup
        setState(() {
          userPointsMap = {for (var point in userPoints) point['action_id']: point};
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
      final int occurrences = userPointsMap[actionId]['occurrences'];
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
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Actions List'),
        ),
        body: actions.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            final actionId = action['id'];
            final actionName = action['action_name'];
            final requiredOccurrences = action['required_occurence'];

            // Check if the action is complete based on occurrences
            final bool isComplete = isActionComplete(actionId, requiredOccurrences);

            // Get the user's current occurrences or default to 0
            final int currentOccurrences = getCurrentOccurrences(actionId);

            return ListTile(
              title: Text(actionName),
              subtitle: Text(
                isComplete
                    ? 'Status: Complete'
                    : 'Status: Incomplete ($currentOccurrences/$requiredOccurrences)',
              ),
              trailing: Icon(
                isComplete ? Icons.check_circle : Icons.hourglass_empty,
                color: isComplete ? Colors.green : Colors.grey,
              ),
            );
          },
        ),
      )

    );
  }


      // Scaffold(
      //   body: SingleChildScrollView(
      //     child: DefaultTabController(
      //       length: 3,
      //       child: Column(
      //         children: [
      //           TabBar(
      //             tabs: const [
      //               Tab(text: "Pending"), // Tab 1
      //               Tab(text: "Completed"),
      //               Tab(text: "Leaderboard"), // Tab 2
      //             ],
      //             labelColor: kPrimaryColor,
      //             indicatorColor: kPrimaryLight,
      //             unselectedLabelColor: themeProvider.themeMode == ThemeModeOptions.light
      //                 ? kScreenDark
      //                 : kDarkBold,
      //           ),
      //           SizedBox(
      //             height: MediaQuery.of(context).size.height,
      //             child: TabBarView(
      //               children: [
      //                 ///Pending actions
      //                 Column(
      //                   children: [
      //                     Expanded(
      //                       child: GridView.builder(
      //                         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      //                           crossAxisCount: 2, // 2 items per row
      //                           crossAxisSpacing: 10,
      //                           mainAxisSpacing: 10,
      //                           childAspectRatio: 0.8, // Adjust aspect ratio if needed
      //                         ),
      //                         itemCount: 3,
      //                         itemBuilder: (context, index) {
      //                           return GamificationSystem().userPointsWidget();
      //                         },
      //                       ),
      //                     ),
      //                   ],
      //                 ),
      //                 ///Completed widgets
      //                 Column(
      //                   children: [
      //                     Expanded(
      //                       child: GridView.builder(
      //                         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      //                           crossAxisCount: 2,
      //                           crossAxisSpacing: 10,
      //                           mainAxisSpacing: 10,
      //                           childAspectRatio: 2,
      //                         ),
      //                         itemCount: 2,
      //                         itemBuilder: (context, index) {
      //                           return GamificationSystem().userPointsWidget();
      //                         },
      //                       ),
      //                     ),
      //                   ],
      //                 ),
      //                 ///Leaderboard
      //                 Column(
      //                   children: [
      //                     Expanded(
      //                       child: GridView.builder(
      //                         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      //                           crossAxisCount: 2,
      //                           crossAxisSpacing: 10,
      //                           mainAxisSpacing: 10,
      //                           childAspectRatio: 2,
      //                         ),
      //                         itemCount: 2,
      //                         itemBuilder: (context, index) {
      //                           return GamificationSystem().userPointsWidget();
      //                         },
      //                       ),
      //                     ),
      //                   ],
      //                 ),
      //               ],
      //             ),
      //           ),
      //         ],
      //       ),
      //     ),
      //   ),
      // ),
    //);
 // }
}
