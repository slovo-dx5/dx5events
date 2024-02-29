class ProposedTopic {
  final String form;
  final Map<String, ProposedTopicDetail> topics;

  ProposedTopic({required this.form, required this.topics});

  factory ProposedTopic.fromJson(Map<String, dynamic> json) {
    var topics = <String, ProposedTopicDetail>{};
    json.forEach((key, value) {
      if (key != "form") {
        topics[key] = ProposedTopicDetail.fromJson(value);
      }
    });
    return ProposedTopic(
      form: json['form'],
      topics: topics,
    );
  }
}

class ProposedTopicDetail {
  final String pzcfn;

  ProposedTopicDetail({required this.pzcfn});

  factory ProposedTopicDetail.fromJson(Map<String, dynamic> json) {
    return ProposedTopicDetail(
      pzcfn: json['pzcfn'],
    );
  }
}
class EventProposal {
  final int id;
  final DateTime dateCreated;
  final DateTime? dateUpdated;
  final int eventId;
  final int speakerId;
  final dynamic topics; // Assuming dynamic because it's null in the given data
  final dynamic roles; // Assuming dynamic because it's null in the given data
  final String reasonForProposal;
  final ProposedTopic proposedTopics;

  EventProposal({
    required this.id,
    required this.dateCreated,
    this.dateUpdated,
    required this.eventId,
    required this.speakerId,
    this.topics,
    this.roles,
    required this.reasonForProposal,
    required this.proposedTopics,
  });

  factory EventProposal.fromJson(Map<String, dynamic> json) {
    return EventProposal(
      id: json['id'],
      dateCreated: DateTime.parse(json['date_created']),
      dateUpdated: json['date_updated'] != null ? DateTime.parse(json['date_updated']) : null,
      eventId: json['event_id'],
      speakerId: json['speaker_id'],
      topics: json['topics'],
      roles: json['roles'],
      reasonForProposal: json['reason_for_proposal'],
      proposedTopics: ProposedTopic.fromJson(json['proposed_topics']),
    );
  }
}

class EventProposalsList {
  final List<EventProposal> proposals;

  EventProposalsList({required this.proposals});

  factory EventProposalsList.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<EventProposal> proposalsList = list.map((i) => EventProposal.fromJson(i)).toList();
    return EventProposalsList(proposals: proposalsList);
  }
}