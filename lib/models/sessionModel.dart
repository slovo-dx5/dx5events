class SessionModel {
  final int id;
  final DateTime dateCreated;
  final int attendeeId;
  final Session session;

  SessionModel({
    required this.id,
    required this.dateCreated,
    required this.attendeeId,
    required this.session,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'],
      dateCreated: DateTime.parse(json['date_created']),
      attendeeId: json['attendee_id'],
      session: Session.fromJson(json['sessions']),
    );
  }
}

class Session {
  final int userId;
  final String startTime;
  final String endTime;
  final String title;
  final String description;
  final String type;
  final int date;
  var speakers;

  Session({
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.type,
    required this.description,
    required this.speakers,
    required this.date,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      userId: json['user_id'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      title: json['title'],
      type: json['type'],
      date:json['date'],
      description: json['description'],
      speakers: json['speakers'],
    );
  }
}
