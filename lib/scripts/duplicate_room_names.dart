import 'package:dx5veevents/dioServices/dioPostService.dart';
import 'package:flutter/material.dart';

import '../dioServices/dioFetchService.dart';
import '../models/lastMinuteCheckinsModel.dart';

class DuplicateRoomNames extends StatefulWidget {
  const DuplicateRoomNames({super.key});

  @override
  State<DuplicateRoomNames> createState() => _DuplicateRoomNamesState();
}

class _DuplicateRoomNamesState extends State<DuplicateRoomNames> {
  bool _isLoading = false;
  bool _isCompleted = false;
  String _currentStatus = '';
  int _currentProgress = 0;
  int _totalRooms = 0;
  String? _errorMessage;
  String _sourceRoomName = '';
  String _targetRoomName = '';
  int _eventId = 74;
  bool isDuplicating=false;

  @override
  void initState() {
    super.initState();
    // Auto-start the duplication process

  }

  Future<List<dynamic>> fetchCheckins({required int eventId, required String existingRoom}) async {
    setState(() {
      _currentStatus = 'Fetching rooms...';
    });

    final response = await DioFetchService().fetchLastMinuteRooms(eventID: eventId, existingRoom: existingRoom);
    if (response.statusCode == 200) {
      final conferenceRoom = ConferenceRoom.fromJson(response.data);
      return conferenceRoom.data;
    } else {
      throw Exception('Failed to fetch rooms');
    }
  }

  Future<void> duplicateRooms({
    required String sourceRoomName,
    required String targetRoomName,
  }) async {
    setState(() {
      _isLoading = true;
      _isCompleted = false;
      _errorMessage = null;
      _currentProgress = 0;
      _sourceRoomName = sourceRoomName;
      _targetRoomName = targetRoomName;
    });

    try {
      final roomsToDuplicate = await fetchCheckins(eventId: _eventId, existingRoom: sourceRoomName);

      setState(() {
        _totalRooms = roomsToDuplicate.length;
        _currentStatus = 'Found ${_totalRooms} rooms to duplicate';
      });

      if (_totalRooms == 0) {
        setState(() {
          _errorMessage = 'No rooms found to duplicate';
          _isLoading = false;
        });
        return;
      }

      for (int i = 0; i < roomsToDuplicate.length; i++) {
        final room = roomsToDuplicate[i];

        setState(() {
          _currentProgress = i + 1;
          _currentStatus = 'Duplicating room ${_currentProgress} of ${_totalRooms}...';
        });

        final payload = {
          'room_name': targetRoomName,
          'attendee_data': room.attendeeData,
          'event_id': _eventId,
        };

        await DioPostService().postLastMinute(body: payload, context: context);

        // Small delay to show progress
        await Future.delayed(const Duration(milliseconds: 200));
      }

      setState(() {
        _isLoading = false;
        _isCompleted = true;
        _currentStatus = 'Successfully duplicated ${_totalRooms} rooms!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
        _currentStatus = 'Failed to duplicate rooms';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duplicate Room Names'),
        backgroundColor: Colors.blue,
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
                      'Room Duplication Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Event ID:', _eventId.toString()),
                    const SizedBox(height: 8),
                    _buildDetailRow('Source Room:', _sourceRoomName.isEmpty ? 'All rooms' : _sourceRoomName),
                    const SizedBox(height: 8),
                    _buildDetailRow('Target Room:', _targetRoomName),
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
                      'Operation Status',
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
                    if (_isLoading && _totalRooms > 0) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _currentProgress / _totalRooms,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_currentProgress / $_totalRooms rooms processed',
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
                              'Duplication completed successfully!',
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
            isDuplicating?CircularProgressIndicator():ElevatedButton(onPressed: (){
              setState(() {
                isDuplicating=true;
                duplicateRooms(
                  sourceRoomName: 'Building Secure and Scalable...', // You can set these values in your code
                  targetRoomName: 'Cybersecurity in connected Govt...', // You can set these values in your code
                );
                isDuplicating=false;

              });
            }, child: Text("Start Duplicating"))
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
          width: 100,
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