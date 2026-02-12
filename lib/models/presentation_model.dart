class PresentationModel {
  final int id;
  final DateTime dateCreated;
  final DateTime? dateUpdated;
  final Reference speaker;
  final String presentationPdf;
  final String topic;
  final String description;
  final int event_id;

  PresentationModel({
    required this.id,
    required this.dateCreated,
    this.dateUpdated,
    required this.speaker,
    required this.description,
    required this.topic,
    required this.presentationPdf,
    required this.event_id,
  });

  factory PresentationModel.fromJson(Map<String, dynamic> json) {
    return PresentationModel(
      id: json['id'],
      dateCreated: DateTime.parse(json['date_created']),
      dateUpdated: json['date_updated'] != null
          ? DateTime.parse(json['date_updated'])
          : null,
      speaker: Reference.fromJson(json['speaker']),
      presentationPdf: json['presentation_pdf'],
      event_id: json['event_id'],
      topic: json['topic'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date_created': dateCreated.toIso8601String(),
      'date_updated': dateUpdated?.toIso8601String(),
      'speaker': speaker.toJson(),
      'presentation_pdf': presentationPdf,
      'event_id': event_id,
      'description': description,
      'topic': topic,
    };
  }
}

class Reference {
  final int key;
  final String collection;

  Reference({
    required this.key,
    required this.collection,
  });

  factory Reference.fromJson(Map<String, dynamic> json) {
    return Reference(
      key: json['key'],
      collection: json['collection'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'collection': collection,
    };
  }
}

class PresentationResponse {
  final List<PresentationModel> data;

  PresentationResponse({required this.data});

  factory PresentationResponse.fromJson(Map<String, dynamic> json) {
    return PresentationResponse(
      data: (json['data'] as List)
          .map((item) => PresentationModel.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((presentation) => presentation.toJson()).toList(),
    };
  }
}
