class SpeakersModel {
  final List<IndividualSpeaker> data;

  SpeakersModel({required this.data});

  factory SpeakersModel.fromJson(Map<String, dynamic> json) {
    return SpeakersModel(
      data: List<IndividualSpeaker>.from(json["data"].map((x) => IndividualSpeaker.fromJson(x))),
    );
  }
}

class IndividualSpeaker {
  final int id;

  final String firstName;
  final String lastName;
  final String? workEmail;
  final String? personalEmail;
  final String? workPhone;
  final String? personalPhone;
  final String company;
  final String role;
  final String? bio;
  final String photo;
  final String? linkedinProfile;
  final String? website;
  final List<String>? allowedContactMethods;

  IndividualSpeaker({
    required this.id,

    required this.firstName,
    required this.lastName,
    this.workEmail,
    this.personalEmail,
    this.workPhone,
    this.personalPhone,
    required this.company,
    required this.role,
    this.bio,
    required this.photo,
    this.linkedinProfile,
    this.website,
    this.allowedContactMethods,
  });

  factory IndividualSpeaker.fromJson(Map<String, dynamic> json) {
    return IndividualSpeaker(
      id: json['id'],

      firstName: json['first_name'],
      lastName: json['last_name'],
      workEmail: json['work_email'],
      personalEmail: json['personal_email'],
      workPhone: json['work_phone'],
      personalPhone: json['personal_phone'],
      company: json['company'],
      role: json['role'],
      bio: json['bio'] ?? "",
      photo: json['photo'],
      linkedinProfile: json['linkedin_profile'],
      website: json['website'],
      allowedContactMethods: json['allowed_contact_methods'] == null ? null : List<String>.from(json['allowed_contact_methods'].map((x) => x)),
    );
  }
}
