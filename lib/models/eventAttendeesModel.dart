

class EventAttendeeModel {
  final int id;

  final String status;
  final String firstName;
  final String lastName;
  final String workEmail;
//  final String? workPhone;
  final String phone;
  final String company;
  final String role;
 // final String industry;
 // final String? interests;
 // final String? modeOfAttendance;

  final String event;
 //final String? registrantType;

  final int eventId;
   int? totalPoints;
  final int attendeeId;
  final String? profilePhoto;

  EventAttendeeModel({
    required this.id,

    required this.status,
    required this.firstName,
    required this.lastName,
    required this.workEmail,
   // this.workPhone,
    required this.phone,
    required this.company,
    required this.role,
     this.totalPoints,
    //required this.industry,
   // this.interests,
   // this.modeOfAttendance,

    required this.event,
  ////  this.registrantType,
    required this.eventId,
    required this.attendeeId,
    required this.profilePhoto,
  });

  factory EventAttendeeModel.fromJson(Map<String, dynamic> json) {
    return EventAttendeeModel(
      id: json['id'],

      status: json['status'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      workEmail: json['work_email'],
      totalPoints: json["total_points"],
      //workPhone: json['work_phone'],
      phone: json['phone'],
      company: json['company'],
      role: json['role'],
      //industry: json['industry'],
      //interests: json['interests'],
      //modeOfAttendance: json['mode_of_attendance'],


      event: json['event'],
      //registrantType: json['registrant_type'],

      eventId: json['eventId'],
      attendeeId: json['attendeeId'],

      profilePhoto: json['profile_photo'],
    );
  }
}


class CustomerAttendeeModel {
  final int id;

  final String status;
  final String? name;
  final String? email;
//  final String? workPhone;
  final String? phone;
  final String? company_role;
 // final String industry;
 // final String? interests;
 // final String? modeOfAttendance;

  final String eventName;
 //final String? registrantType;

  final int eventID;
  final int ?totalPoints;
  final int attendeeId;
  final String? profilePhoto;

  CustomerAttendeeModel({
    required this.id,

    required this.status,
     this.name,
     this.email,
    this.totalPoints,
   // this.workPhone,
     this.phone,
     this.company_role,
    //required this.industry,
   // this.interests,
   // this.modeOfAttendance,

    required this.eventName,
  ////  this.registrantType,
    required this.eventID,
    required this.attendeeId,
     this.profilePhoto,
  });

  factory CustomerAttendeeModel.fromJson(Map<String, dynamic> json) {
    return CustomerAttendeeModel(
      id: json['id'],

      status: json['status'],
      name: json['name'],
      email: json['email'],
      totalPoints: json['total_points'],
      //workPhone: json['work_phone'],
      phone: json['phone'],
      company_role: json['company_role'],



      eventName: json['eventName'],

      eventID: json['eventID'],
      attendeeId: json['attendeeId'],

      profilePhoto: json['profile_photo'],
    );
  }
}
