import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../constants.dart';
import '../../dioServices/dioFetchService.dart';
import '../../helpers/helper_widgets.dart';
import '../../models/cisoAttendeesModel.dart';
import '../../providers.dart';

class AttendeesScreen extends StatefulWidget {
  const AttendeesScreen({super.key});

  @override
  State<AttendeesScreen> createState() => _AttendeesScreenState();
}

class _AttendeesScreenState extends State<AttendeesScreen> {
  RefreshController _refreshController = RefreshController();

  List<CISOAttendeeModel>? attendeesList;
  List<CISOAttendeeModel>? filteredattendeesList;
  bool isSearching = false;
  Dio dio = Dio();
  DioCacheManager dioCacheManager = DioCacheManager(CacheConfig());
  final TextEditingController _searchController = TextEditingController();
  //List<Map<String, dynamic>> filteredData = [];
  @override
  void initState() {
    super.initState();
    dio.interceptors.add(dioCacheManager.interceptor);

    //  filteredData = dummyData;
    fetchAllAttendees().then((value) {
      setState(() {
        attendeesList = value;
        filteredattendeesList = attendeesList;
      });
    });
  }

  Future fetchAllAttendees() async {
    final response = await DioFetchService().fetchCISOAttendees();

    setState(() {
      //isFetching=false;
    });

    if (response.statusCode == 200) {
      final rawData = response.data['data'];
      List<dynamic> filteredData = rawData
          .where((item) =>
              item['event'] == "Africa CISO Summit" &&
              item['status'] == "approved")
          .toList();


      return filteredData
          .map((userJson) => CISOAttendeeModel.fromJson(userJson))
          .toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  void filterData(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredattendeesList = attendeesList;
      } else {
        filteredattendeesList = attendeesList!.where((data) {
          final fullName = '${data.firstName}';
          return fullName.toLowerCase().contains(query.toLowerCase()) ||
              data.lastName.toLowerCase().contains(query.toLowerCase()) ||
              data.role.toLowerCase().contains(query.toLowerCase()) ||
              data.company.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
        appBar: AppBar(automaticallyImplyLeading: true,
          centerTitle: true,
          title: isSearching
              ? TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by Name, Role or Company',
                    hintStyle: TextStyle(fontSize: 12,color: kWhiteText),
                    border: InputBorder.none,
                  ),
                  onChanged: (query) {
                    filterData(query);
                  },
                )
              : const Column(
                  children: [
                    Text(
                      "ATTENDEES",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),

                  ],
                ),
          actions: [
            IconButton(
              icon: Icon(isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  isSearching = !isSearching;
                  if (!isSearching) {
                    _searchController.clear();
                    filterData('');
                  }
                });
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: filteredattendeesList == null
              ? const Center(
                  child: SpinKitCircle(
                    color: kCIOPink,
                  ),
                )
              : SmartRefresher(
                  controller: _refreshController,
                  enablePullDown: true,
                  header: const WaterDropHeader(
                    waterDropColor: kCIOPink,
                  ),
                  onRefresh: () async {
                    await dioCacheManager.clearAll();
                    await fetchAllAttendees();
                    setState(() {
                      _refreshController.refreshCompleted();
                    });
                  },
                  onLoading: () async {
                    await Future.delayed(Duration(milliseconds: 1000));
                    setState(() {
                      _refreshController.loadComplete();
                    });
                  },
                  child: ListView.builder(
                    itemCount: filteredattendeesList!.length,
                    itemBuilder: (context, index) {
                      final user = filteredattendeesList![index];
                      return profileProvider.userID == user.id
                          ? meWidget(
                              assetName: "assetName",
                              context: context,
                              firstName: user.firstName,
                              lastName: user.lastName,
                              role: user.role,
                              company: user.company,
                              interests: [],
                              profileid: user.profilePhoto ?? "",
                              userID: user.id)
                          : attendeeWidget(
                              assetName: "assetName",
                              context: context,
                              firstName: user.firstName,
                              lastName: user.lastName,
                              role: user.role,
                              company: user.company,
                              interests: [],
                              profileid: user.profilePhoto ?? "",
                              userID: user.id);
                    },

                    // itemCount: filteredData.length,
                    // itemBuilder: (context,index){
                    //   final data = filteredData[index];
                    //   return attendeeWidget(
                    //     assetName: data['assetname']!,
                    //     context: context,
                    //     firstName: "${data["firstname"]}",
                    //     lastName:  "${data["lastname"]}",
                    //     role:data["role"]!,
                    //     company:data["company"]!,
                    //     bio: data["bio"]??"",
                    //     interests: data["interests"]!,
                    //
                    //   );
                    // }
                  ),
                ),
        ));
  }
}
