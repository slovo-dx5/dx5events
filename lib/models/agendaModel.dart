class AgendaModel {
 // final int id;

  final List<AgendaDay> days;

  AgendaModel({
  //  required this.id,

    required this.days,
  });

  factory AgendaModel.fromJson(Map<String, dynamic> json) {
    return AgendaModel(
     // id: json['data']['id'],

      days: List<AgendaDay>.from(json['data'][0]['day'].map((x) => AgendaDay.fromJson(x))),
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



class AgendaDay {
   var date;
   List<Session> sessions;

  AgendaDay({
    required this.date,
    required this.sessions,
  });

  factory AgendaDay.fromJson(Map<String, dynamic> json) {
    return AgendaDay(
      date: DateTime.parse(json['date']),      sessions: List<Session>.from(json['sessions'].map((x) => Session.fromJson(x))),
    );
  }
}

class Session {
  var  startTime;
  var endTime;
  var title;
  var sessionType;
  var summary;
  int sessionId;
  final List<SpeakerAssignment>? speakers;
  final List<BreakoutSession>? breakoutSessions;

  Session({
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.summary,
    required this.sessionId,
    required this.sessionType,    this.speakers,    this.breakoutSessions,
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
      summary: json['Summary'] ?? "",
      sessionType: json['session_type']?? "",
        breakoutSessions: json['breakout_sessions'] == null ? null : List<BreakoutSession>.from(json['breakout_sessions'].map((x) => BreakoutSession.fromJson(x))),
      speakers: speakers,
      sessionId: json['session_id']??1600,
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
  var key;
   var collection;

  SpeakerReference({
    required this.key,
    required this.collection,
  });

  factory SpeakerReference.fromJson(Map<String, dynamic> json) => SpeakerReference(
    key: json['key'],
    collection: json['collection'],
  );
}

class BreakoutSession {
  final String title;
  final String type;
  final String summary;
  final List<Speaker>? speakers;

  BreakoutSession({
    required this.title,
    required this.type,
    required this.summary,
     this.speakers,
  });

  factory BreakoutSession.fromJson(Map<String, dynamic> json) {
   // var speakersList = json['breakout_session_speakers'] as List;
   // List<Speaker> speakerObjects = speakersList.map((speakerJson) => Speaker.fromJson(speakerJson)).toList();

    return BreakoutSession(
      title: json['breakout_session_title'],
      type: json['breakout_session_type'],
      summary: json['breakout_session_summary'] ??"Summary",
      //speakers: speakerObjects,
    );
  }
}

class Speaker {
  var key;
  final String collection;
  final String assumedRole;

  Speaker({required this.key, required this.collection, required this.assumedRole});

  factory Speaker.fromJson(Map<String, dynamic> json) {
    return Speaker(
      key: json['speaker']['key'],
      collection: json['speaker']['collection'],
      assumedRole: json['assumed_role'],
    );
  }
}


