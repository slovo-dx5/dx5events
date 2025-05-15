import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../constants.dart';
import '../helpers/helper_functions.dart';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class IncomingMeetingWidget extends StatelessWidget {
  final String startTime;
  final String message;
  final String requesterName;
  final bool isAccepting;
  final VoidCallback acceptMeetingFunc;
  final VoidCallback declineMeetingFunc;

  const IncomingMeetingWidget({
    Key? key,
    required this.startTime,
    required this.isAccepting,
    required this.acceptMeetingFunc,
    required this.declineMeetingFunc,
    required this.message,
    required this.requesterName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      surfaceTintColor: kConnectedBlue,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withOpacity(0.05),
              Colors.green.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF7ED),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_available,
                        size: 16,
                        color: Color(0xFF4CAF50), // Success green
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "New Request",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF4CAF50), // Success green
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Time badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "Today, $startTime - ${_addThirtyMinutes(startTime)}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Requester info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
                  child: Text(
                    requesterName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requesterName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Wants to meet with you",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Message section
            Text(
              "Message",
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Text(
                message,
                style: theme.textTheme.bodyMedium,
              ),
            ),

            const SizedBox(height: 20),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: declineMeetingFunc,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("Decline"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:kConnectedRed,
                      side: BorderSide(color: kConnectedRed),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),

                const SizedBox(width: 12),
                Expanded(
                  child: isAccepting
                      ? const SpinKitCircle(color: kConnectedGreen, size: 20): OutlinedButton.icon(
                   icon: Icon(Icons.check, size: 18),
                    label: const Text("Accept"),
                    onPressed: acceptMeetingFunc,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kConnectedGreen.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                   
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _addThirtyMinutes(String time) {
    // This is a placeholder for the original addThirtyMinutes function
    // Assuming the original function logic is implemented elsewhere
    // Just for demonstration, we'll make a simple implementation
    final parts = time.split(':');
    if (parts.length != 2) return time;

    int hour = int.tryParse(parts[0]) ?? 0;
    int minute = int.tryParse(parts[1]) ?? 0;

    minute += 30;
    if (minute >= 60) {
      minute -= 60;
      hour += 1;
    }
    if (hour >= 24) {
      hour -= 24;
    }

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
