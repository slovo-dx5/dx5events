class AgendaModel {
 // final int id;

  final List<Day> days;

  AgendaModel({
  //  required this.id,

    required this.days,
  });

  factory AgendaModel.fromJson(Map<String, dynamic> json) {
    return AgendaModel(
     // id: json['data']['id'],

      days: List<Day>.from(json['data']['day'].map((x) => Day.fromJson(x))),
    );
  }


  List<int> fetchSpeakerKeys() {
    List<int> speakerKeys = [];
    for (var day in days) {
      for (var session in day.sessions) {
        speakerKeys.addAll(session.speakers!.map((s) => s.speaker.key));
      }
    }
    return speakerKeys;
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
    var speakersJson = json['speakers'] as List<dynamic>?; // Cast as List<dynamic>? to handle null
    List<SpeakerAssignment> speakers = speakersJson != null
        ? speakersJson.map((x) => SpeakerAssignment.fromJson(x)).toList()
        : []; // Use an empty list if 'speakers' is null
    return Session(
      startTime: json['start_time'],
      endTime: json['end_time'],
      title: json['title'],
      sessionType: json['session_type'],
      speakers: speakers
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
