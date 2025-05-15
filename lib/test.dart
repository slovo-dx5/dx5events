import 'package:flutter/material.dart';

class OutgoingMeetingWidget extends StatelessWidget {
  final String startTime;
  final String message;
  final String wantsToMeetWithName;
  final bool isAccepting;
  final VoidCallback acceptMeetingFunc;
  final VoidCallback declineMeetingFunc;

  const OutgoingMeetingWidget({
    Key? key,
    required this.startTime,
    required this.isAccepting,
    required this.acceptMeetingFunc,
    required this.declineMeetingFunc,
    required this.message,
    required this.wantsToMeetWithName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
                    color: const Color(0xFFFFF0EA), // Light version of kCIOPink
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule_send,
                        size: 16,
                        color: Color(0xFFE94E77), // kCIOPink
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Request sent",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFE94E77), // kCIOPink
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
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
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

            // Recipient info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE94E77).withOpacity(0.2),
                  child: Text(
                    wantsToMeetWithName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFE94E77),
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
                        wantsToMeetWithName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Meeting request recipient",
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
              "Your message",
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: declineMeetingFunc,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text("Cancel Request"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red[300]!),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: acceptMeetingFunc,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit Request"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF53BFA1), // A nice teal color
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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