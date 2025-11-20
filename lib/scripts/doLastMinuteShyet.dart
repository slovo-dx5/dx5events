import 'dart:convert';
import 'dart:developer';

import 'package:dx5veevents/dioServices/dioPostService.dart';
import 'package:flutter/material.dart';

import '../dioServices/dioFetchService.dart';
import '../models/lastMinuteCheckinsModel.dart';

class StructureLAstMinute extends StatefulWidget {
  const StructureLAstMinute({super.key});

  @override
  State<StructureLAstMinute> createState() => _StructureLAstMinuteState();
}

class _StructureLAstMinuteState extends State<StructureLAstMinute> {
  bool _isLoading = false;
  bool _isCompleted = false;
  String _currentStatus = '';
  int _currentProgress = 0;
  int _totalCheckins = 0;
  String? _errorMessage;
  final int _eventId = 59;
  List<String> _processedAttendees = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchCheckins(eventId: _eventId);
    });
  }

  Future<void> fetchCheckins({required int eventId}) async {
    setState(() {
      _isLoading = true;
      _isCompleted = false;
      _errorMessage = null;
      _currentProgress = 0;
      _currentStatus = 'Fetching check-ins...';
      _processedAttendees.clear();
    });

    try {
      final response = await DioFetchService().fetchLastMinuteCheckins(eventID: eventId);
      ConferenceRoom conferenceRoom = ConferenceRoom.fromJson(response.data);

      setState(() {
        _totalCheckins = conferenceRoom.data.length;
        _currentStatus = 'Found ${_totalCheckins} check-ins to process';
      });

      if (_totalCheckins == 0) {
        setState(() {
          _isCompleted = true;
          _currentStatus = 'No check-ins found to process';
          _isLoading = false;
        });
        return;
      }

      for (int i = 0; i < conferenceRoom.data.length; i++) {
        var roomData = conferenceRoom.data[i];
        int attendeeId = roomData.attendeeId;

        setState(() {
          _currentProgress = i + 1;
          _currentStatus = 'Processing attendee $attendeeId (${_currentProgress}/${_totalCheckins})';
        });

        try {
          // Fetch attendee details
          var response = await DioFetchService().fetchSingleAttendeeForEvent(id: attendeeId, eventID: eventId);
          var data = response.data["data"];

          // Ensure the data list is not empty
          if (data != null && data.isNotEmpty) {
            var attendeeDetails = data[0];

            // Post check-in data
            await DioPostService().postCheckinDataFiltered(body: {
              "email": attendeeDetails["work_email"] ?? "email not present",
              "First_Name": attendeeDetails["first_name"] ?? "missing value",
              "Last_Name": attendeeDetails["last_name"] ?? "missing value",
              "Phone": attendeeDetails["phone"] ?? "missing value",
              "Company": attendeeDetails["company"],
              "Role": attendeeDetails["role"],
              "Event_ID": eventId,
              "Attendee_ID": attendeeId,
              "Session_Name": roomData.roomName
            }, context: context);

            setState(() {
              _processedAttendees.add('${attendeeDetails["first_name"]} ${attendeeDetails["last_name"]} - ${roomData.roomName}');
            });

            print("post successful");
          } else {
            // Handle the case where no attendee details are found
            print('No attendee details found for attendee ID: $attendeeId');
            print("response is ${response.data}");

            setState(() {
              _processedAttendees.add('Attendee ID: $attendeeId - No details found');
            });
          }
        } catch (e) {
          print('Error processing attendee $attendeeId: $e');
          setState(() {
            _processedAttendees.add('Attendee ID: $attendeeId - Error: ${e.toString()}');
          });
        }

        // Small delay to show progress
        await Future.delayed(const Duration(milliseconds: 100));
      }

      setState(() {
        _isLoading = false;
        _isCompleted = true;
        _currentStatus = 'Successfully processed ${_totalCheckins} check-ins!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
        _currentStatus = 'Failed to process check-ins';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Structure Last Minute Check-ins'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Processing Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Event ID:', _eventId.toString()),
                    const SizedBox(height: 8),
                    _buildDetailRow('Total Check-ins:', _totalCheckins.toString()),
                    const SizedBox(height: 8),
                    _buildDetailRow('Processed:', _currentProgress.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading) ...[
                      Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_currentStatus)),
                        ],
                      ),
                    ] else if (_isCompleted) ...[
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_currentStatus)),
                        ],
                      ),
                    ] else if (_errorMessage != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_currentStatus)),
                        ],
                      ),
                    ] else ...[
                      const Text('Initializing...'),
                    ],
                    if (_isLoading && _totalCheckins > 0) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _currentProgress / _totalCheckins,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_currentProgress / $_totalCheckins check-ins processed',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_isCompleted) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Processing completed successfully!',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_processedAttendees.isNotEmpty) ...[
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Processed Attendees (${_processedAttendees.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _processedAttendees.length,
                            itemBuilder: (context, index) {
                              final attendee = _processedAttendees[index];
                              final isError = attendee.contains('Error') || attendee.contains('No details found');

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      isError ? Icons.warning : Icons.check_circle_outline,
                                      size: 16,
                                      color: isError ? Colors.orange : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        attendee,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isError ? Colors.orange : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}