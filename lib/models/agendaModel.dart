class SpeakerSession {
  final String title;
  final DateTime date;
  final String startTime;
  final String endTime;

  SpeakerSession({
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
  });
}

class AgendaModel {
 // final int id;

  final List<AgendaDay> days;

  AgendaModel({
  //  required this.id,

    required this.days,
  });

  factory AgendaModel.fromJson(Map<String, dynamic> json) {
    // Guard against an empty/missing `data` array or a missing `day` list,
    // which the API returns when no agenda has been published yet. Without
    // this, `data[0]` throws RangeError (Valid value range is empty: 0).
    final data = json['data'];
    if (data is! List || data.isEmpty) {
      return AgendaModel(days: []);
    }

    final dayList = (data[0] is Map) ? data[0]['day'] : null;
    if (dayList is! List) {
      return AgendaModel(days: []);
    }

    return AgendaModel(
     // id: json['data']['id'],

      days: List<AgendaDay>.from(dayList.map((x) => AgendaDay.fromJson(x))),
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
  var stage;
  final List<SpeakerAssignment>? speakers;
  final List<BreakoutSession>? breakoutSessions;

  Session({
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.summary,
    required this.sessionId,
    required this.sessionType,
    this.stage,
    this.speakers,    this.breakoutSessions,
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
      stage: json['stage'],
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
  var title;
 var type;
  var summary;
  final List<Speaker>? speakers;

  BreakoutSession({
    this.title,
     this.type,
     this.summary,
     this.speakers,
  });

  factory BreakoutSession.fromJson(Map<String, dynamic> json) {
    final speakersJson = json['breakout_session_speakers'] as List<dynamic>?;
    final speakerObjects = speakersJson != null
        ? speakersJson
            .where((x) => x is Map && x['speaker'] != null && x['speaker']['key'] != null)
            .map((x) => Speaker.fromJson(Map<String, dynamic>.from(x as Map)))
            .toList()
        : <Speaker>[];

    return BreakoutSession(
      title: json['breakout_session_title'],
      type: json['breakout_session_type'],
      summary: json['breakout_session_summary'] ??"Summary",
      speakers: speakerObjects,
    );
  }
}

class Speaker {
  var key;
  var collection;
  var assumedRole;

  Speaker({required this.key,  this.collection,  this.assumedRole});

  factory Speaker.fromJson(Map<String, dynamic> json) {
    return Speaker(
      key: json['speaker']['key'],
      collection: json['speaker']['collection'],
      assumedRole: json['assumed_role'],
    );
  }
}


