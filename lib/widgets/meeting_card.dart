import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum MeetingStatus {
  accepted,
  pending,
}

class MeetingData {
  final DateTime meetingTime;
  final String topic;
  final MeetingStatus status;
  final List<String> participants;

  MeetingData({
    required this.meetingTime,
    required this.topic,
    required this.status,
    required this.participants,
  });
}

class MeetingCard extends StatelessWidget {
  final MeetingData meeting;
  final VoidCallback? onTap;

  const MeetingCard({
    Key? key,
    required this.meeting,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      meeting.topic,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(meeting.meetingTime),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Participants',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildParticipantsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: meeting.status == MeetingStatus.accepted
            ? Colors.green.shade50
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: meeting.status == MeetingStatus.accepted
              ? Colors.green.shade300
              : Colors.orange.shade300,
        ),
      ),
      child: Text(
        meeting.status == MeetingStatus.accepted ? 'Accepted' : 'Pending',
        style: TextStyle(
          fontSize: 12,
          color: meeting.status == MeetingStatus.accepted
              ? Colors.green.shade700
              : Colors.orange.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildParticipantsList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: meeting.participants.map((participant) {
        return _buildParticipantChip(participant);
      }).toList(),
    );
  }

  Widget _buildParticipantChip(String name) {
    final initials = name.split(' ')
        .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
        .join('')
        .substring(0, name.split(' ').length > 1 ? 2 : 1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          name,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat('h:mm a');
    return '${dateFormat.format(dateTime)} at ${timeFormat.format(dateTime)}';
  }
}

// Example usage
class MeetingCardExample extends StatelessWidget {
  const MeetingCardExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample meeting data
    final MeetingData sampleMeeting = MeetingData(
      meetingTime: DateTime.now().add(const Duration(days: 2, hours: 3)),
      topic: "Q2 Product Strategy",
      status: MeetingStatus.accepted,
      participants: [
        "Jane Smith",
        "John Doe",
        "Alice Johnson",
        "Bob Williams"
      ],
    );

    final MeetingData pendingMeeting = MeetingData(
      meetingTime: DateTime.now().add(const Duration(days: 1)),
      topic: "Budget Review",
      status: MeetingStatus.pending,
      participants: [
        "Michael Chen",
        "Sarah Lee",
        "David Wong",
      ],
    );

    return Column(
      children: [
        MeetingCard(
          meeting: sampleMeeting,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Accepted meeting tapped')),
            );
          },
        ),
        MeetingCard(
          meeting: pendingMeeting,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pending meeting tapped')),
            );
          },
        ),
      ],
    );
  }
}