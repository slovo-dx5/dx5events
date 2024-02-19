class AgendaModel {
 // final int id;

  final List<Day> day;

  AgendaModel({
  //  required this.id,

    required this.day,
  });

  factory AgendaModel.fromJson(Map<String, dynamic> json) {
    return AgendaModel(
     // id: json['data']['id'],

      day: List<Day>.from(json['data']['day'].map((x) => Day.fromJson(x))),
    );
  }
}

class Day {
  final String date;
  final List<Session> sessions;

  Day({
    required this.date,
    required this.sessions,
  });

  factory Day.fromJson(Map<String, dynamic> json) {
    return Day(
      date: json['date'],
      sessions: List<Session>.from(json['sessions'].map((x) => Session.fromJson(x))),
    );
  }
}

class Session {
  final String startTime;
  final String endTime;
  final String title;
  final String sessionType;
  final List<SpeakerAssignment>? speakers;

  Session({
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.sessionType,    this.speakers,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      startTime: json['start_time'],
      endTime: json['end_time'],
      title: json['title'],
      sessionType: json['session_type'],
      speakers: json['speakers'] == null
          ? null
          : List<SpeakerAssignment>.from(json['speakers'].map((x) => SpeakerAssignment.fromJson(x))),

    );
  }
}
class SpeakerAssignment {
  final SpeakerReference speaker;
  final String? assumedRole;

  SpeakerAssignment({
    required this.speaker,
    this.assumedRole,
  });

  factory SpeakerAssignment.fromJson(Map<String, dynamic> json) => SpeakerAssignment(
    speaker: SpeakerReference.fromJson(json['speaker']),
    assumedRole: json['assumed_role'],
  );
}
class SpeakerReference {
  final int key;
  final String collection;

  SpeakerReference({
    required this.key,
    required this.collection,
  });

  factory SpeakerReference.fromJson(Map<String, dynamic> json) => SpeakerReference(
    key: json['key'],
    collection: json['collection'],
  );
}
