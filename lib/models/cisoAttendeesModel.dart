// class CISOAttendeesModel {
//   final List<Registrant> data;
//
//   CISOAttendeesModel({required this.data});
//
//   factory CISOAttendeesModel.fromJson(Map<String, dynamic> json) {
//     var list = json['data'] as List;
//     List<Registrant> dataList = list.map((i) => Registrant.fromJson(i)).toList();
//     return CISOAttendeesModel(data: dataList);
//   }
// }

class CISOAttendeeModel {
  final int id;

  final String status;
  final String firstName;
  final String lastName;
  final String workEmail;
  final String? workPhone;
  final String phone;
  final String company;
  final String role;
  final String industry;
  final String? interests;
  final String? modeOfAttendance;

  final String event;
  final String? registrantType;

  final int eventId;
  final int attendeeId;
  final String? profilePhoto;

  CISOAttendeeModel({
    required this.id,

    required this.status,
    required this.firstName,
    required this.lastName,
    required this.workEmail,
    this.workPhone,
    required this.phone,
    required this.company,
    required this.role,
    required this.industry,
    this.interests,
    this.modeOfAttendance,

    required this.event,
    this.registrantType,
    required this.eventId,
    required this.attendeeId,
    required this.profilePhoto,
  });

  factory CISOAttendeeModel.fromJson(Map<String, dynamic> json) {
    return CISOAttendeeModel(
      id: json['id'],

      status: json['status'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      workEmail: json['work_email'],
      workPhone: json['work_phone'],
      phone: json['phone'],
      company: json['company'],
      role: json['role'],
      industry: json['industry'],
      interests: json['interests'],
      modeOfAttendance: json['mode_of_attendance'],


      event: json['event'],
      registrantType: json['registrant_type'],

      eventId: json['eventId'],
      attendeeId: json['attendeeId'],

      profilePhoto: json['profile_photo'],
    );
  }
}
