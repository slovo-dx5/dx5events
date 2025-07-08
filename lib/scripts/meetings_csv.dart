import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:downloadsfolder/downloadsfolder.dart';

import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class MeetingsExporter {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Exports all meetings from all users to a CSV file
  Future<String> exportMeetingsToCSV() async {
    try {
      // Get all user documents
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();

      List<List<String>> csvData = [];

      // Add CSV headers
      csvData.add([
        'User ID',
        'Meeting ID',
        'Requested By',
        'Wants to Meet With',
        'Start Time',
        'Date Requested'
      ]);

      // Process each user
      for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
        String userId = userDoc.id;

        try {
          // Check if this user has a meetings collection
          QuerySnapshot meetingsSnapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('meetings')
              .get();

          // Process each meeting document
          for (QueryDocumentSnapshot meetingDoc in meetingsSnapshot.docs) {
            Map<String, dynamic> meetingData = meetingDoc.data() as Map<String, dynamic>;
            String meetingId = meetingDoc.id;

            // Extract the required fields with null safety
            String requestedBy = meetingData['requested_by']?.toString() ?? '';
            String wantsToMeetWith = meetingData['wants_to_meet_with']?.toString() ?? '';
            String startTime = _formatTimestamp(meetingData['start_time']);
            String dateRequested = _formatTimestamp(meetingData['date_requested']);

            // Add row to CSV data
            csvData.add([
              userId,
              meetingId,
              requestedBy,
              wantsToMeetWith,
              startTime,
              dateRequested
            ]);
          }
        } catch (e) {
          // User doesn't have meetings collection or other error - skip
          print('No meetings found for user $userId or error occurred: $e');
          continue;
        }
      }

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);

      // Save to file
      String filePath = await _saveCsvFile(csvString);

      print('Successfully exported ${csvData.length - 1} meetings to: $filePath');
      return filePath;

    } catch (e) {
      print('Error exporting meetings: $e');
      throw Exception('Failed to export meetings: $e');
    }
  }

  /// Helper method to format Firestore Timestamps
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      if (timestamp is Timestamp) {
        DateTime dateTime = timestamp.toDate();
        return dateTime.toIso8601String();
      } else if (timestamp is String) {
        return timestamp;
      } else {
        return timestamp.toString();
      }
    } catch (e) {
      return timestamp.toString();
    }
  }

  /// Save CSV string to file
  Future<String> _saveCsvFile(String csvContent) async {
    try {
      // Get the documents directory
      Directory documentsDirectory = await getApplicationDocumentsDirectory();

      // Create file path with timestamp
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      Directory downloadsDir = await getDownloadDirectory();
      String filePath = '${downloadsDir.path}/meetings_export_$timestamp.csv';

      // Write file
      File file = File(filePath);
      await file.writeAsString(csvContent);

      return filePath;
    } catch (e) {
      throw Exception('Failed to save CSV file: $e');
    }
  }

  /// Alternative method that processes users in batches for better performance
  Future<String> exportMeetingsToCSVBatched({int batchSize = 100}) async {
    try {
      List<List<String>> csvData = [];

      // Add CSV headers
      csvData.add([
        'User ID',
        'Meeting ID',
        'Requested By',
        'Wants to Meet With',
        'Start Time',
        'Date Requested'
      ]);

      DocumentSnapshot? lastDoc;
      bool hasMore = true;

      while (hasMore) {
        Query query = _firestore.collection('users').limit(batchSize);

        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        QuerySnapshot batch = await query.get();

        if (batch.docs.isEmpty) {
          hasMore = false;
          break;
        }

        // Process this batch
        for (QueryDocumentSnapshot userDoc in batch.docs) {
          String userId = userDoc.id;

          try {
            QuerySnapshot meetingsSnapshot = await _firestore
                .collection('users')
                .doc(userId)
                .collection('meetings')
                .get();

            for (QueryDocumentSnapshot meetingDoc in meetingsSnapshot.docs) {
              Map<String, dynamic> meetingData = meetingDoc.data() as Map<String, dynamic>;

              csvData.add([
                userId,
                meetingDoc.id,
                meetingData['requested_by']?.toString() ?? '',
                meetingData['wants_to_meet_with']?.toString() ?? '',
                _formatTimestamp(meetingData['start_time']),
                _formatTimestamp(meetingData['date_requested'])
              ]);
            }
          } catch (e) {
            print('Error processing user $userId: $e');
            continue;
          }
        }

        lastDoc = batch.docs.last;
        hasMore = batch.docs.length == batchSize;
      }

      // Convert to CSV and save
      String csvString = const ListToCsvConverter().convert(csvData);
      String filePath = await _saveCsvFile(csvString);

      print('Successfully exported ${csvData.length - 1} meetings to: $filePath');
      return filePath;

    } catch (e) {
      throw Exception('Failed to export meetings in batches: $e');
    }
  }
}

// Usage example in a widget or service
class MeetingsExportService {
  final MeetingsExporter _exporter = MeetingsExporter();

  /// Export meetings with progress callback
  Future<void> exportMeetings({Function(String)? onProgress}) async {
    try {
      onProgress?.call('Starting export...');

      String filePath = await _exporter.exportMeetingsToCSV();

      onProgress?.call('Export completed successfully!');
      onProgress?.call('File saved to: $filePath');

    } catch (e) {
      onProgress?.call('Export failed: $e');
      rethrow;
    }
  }

  /// Export with batching for large datasets
  Future<void> exportMeetingsBatched({Function(String)? onProgress}) async {
    try {
      onProgress?.call('Starting batched export...');

      String filePath = await _exporter.exportMeetingsToCSVBatched(batchSize: 50);

      onProgress?.call('Batched export completed!');
      onProgress?.call('File saved to: $filePath');

    } catch (e) {
      onProgress?.call('Batched export failed: $e');
      rethrow;
    }
  }
}

// Example usage in a Flutter widget

class ExportMeetingsButton extends StatefulWidget {
  @override
  _ExportMeetingsButtonState createState() => _ExportMeetingsButtonState();
}

class _ExportMeetingsButtonState extends State<ExportMeetingsButton> {
  final MeetingsExportService _exportService = MeetingsExportService();
  bool _isExporting = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Column(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _isExporting ? null : _exportMeetings,
          child: Text(_isExporting ? 'Exporting...' : 'Export Meetings to CSV'),
        ),
        if (_status.isNotEmpty)
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(_status),
          ),
      ],
    ),);
  }

  Future<void> _exportMeetings() async {
    setState(() {
      _isExporting = true;
      _status = '';
    });

    try {
      await _exportService.exportMeetings(
        onProgress: (message) {
          setState(() {
            _status = message;
          });
        },
      );
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }
}
