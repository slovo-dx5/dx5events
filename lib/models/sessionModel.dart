

import 'dart:convert';

// Define the EventData model class
class SessionModel {
  int id;
  int attendeeId;
  String eventDate;
  int sessionId;

  SessionModel({
    required this.id,
    required this.attendeeId,
    required this.eventDate,
    required this.sessionId,
  });

  // Factory method to create an EventData instance from a JSON object
  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'],
      attendeeId: json['attendee_id'],
      eventDate: json['event_date'],
      sessionId: json['session_id'],
    );
  }

  // Method to convert an EventData instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attendee_id': attendeeId,
      'event_date': eventDate,
      'session_id': sessionId,
    };
  }
}

class DataResponse {
  List<SessionModel> data;

  DataResponse({required this.data});

  factory DataResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List;
    List<SessionModel> eventDataList = dataList.map((item) => SessionModel.fromJson(item)).toList();

    return DataResponse(data: eventDataList);
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

