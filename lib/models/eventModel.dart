class Event {
  final int id;
  final String titleSlug;
  final Agenda agenda;
  final List<SpeakerAssociation> speakers;
  final List<SponsorAssociation> sponsors;
  final List<PartnerAssociation> partners;
  final String theme;

  Event({
    required this.id,
    required this.titleSlug,
    required this.agenda,
    required this.speakers,
    required this.sponsors,
    required this.partners,
    required this.theme,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      titleSlug: json['title_slug'],
      agenda: Agenda.fromJson(json['agenda']),
      speakers: List<SpeakerAssociation>.from(
          json['speakers'].map((x) => SpeakerAssociation.fromJson(x))),
      sponsors: List<SponsorAssociation>.from(
          json['sponsors'].map((x) => SponsorAssociation.fromJson(x))),
      partners: List<PartnerAssociation>.from(
          json['partners'].map((x) => PartnerAssociation.fromJson(x))),
      theme: json['theme'],
    );
  }

  List<int> fetchSpeakerKeys() {
    List<int> speakerKeys = [];

    speakerKeys.addAll(speakers.map((s) => s.speaker.key));


    return speakerKeys;
  }

  List<int> fetchSponsorsKeys() {
    List<int> sponsorKeys = [];

    sponsorKeys.addAll(sponsors.map((s) => s.sponsor.key));


    return sponsorKeys;
  }

  List<int> fetchPartnerKeys() {
    List<int> partnerKeys = [];

    partnerKeys.addAll(partners.map((s) => s.partners.key));


    return partnerKeys;
  }

}



class Agenda {
  final int key;
  final String collection;

  Agenda({required this.key, required this.collection});

  factory Agenda.fromJson(Map<String, dynamic> json) {
    return Agenda(
      key: json['key'],
      collection: json['collection'],
    );
  }
}

class SpeakerAssociation {
  final Reference speaker;
//  final String assumedRole;

  SpeakerAssociation({required this.speaker, });

  factory SpeakerAssociation.fromJson(Map<String, dynamic> json) {
    return SpeakerAssociation(
      speaker: Reference.fromJson(json['speaker']),
    //  assumedRole: json['assumed_role'],
    );
  }
}

class SponsorAssociation {
  final Reference sponsor;
  final String category;

  SponsorAssociation({required this.sponsor, required this.category});

  factory SponsorAssociation.fromJson(Map<String, dynamic> json) {
    return SponsorAssociation(
      sponsor: Reference.fromJson(json['sponsor']),
      category: json['category'],
    );
  }
}

class PartnerAssociation {
  final Reference partners;

  PartnerAssociation({required this.partners});

  factory PartnerAssociation.fromJson(Map<String, dynamic> json) {
    return PartnerAssociation(
      partners: Reference.fromJson(json['partners']),
    );
  }
}

class Reference {
  final int key;
  final String collection;

  Reference({required this.key, required this.collection});

  factory Reference.fromJson(Map<String, dynamic> json) {
    return Reference(
      key: json['key'],
      collection: json['collection'],
    );
  }
}
