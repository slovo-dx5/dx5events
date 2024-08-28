class CustomerContact {
  final String? name;
  final String? company_role;
  final String? email;
  var phone;
  final int attendeeId;
  final int eventID;
  final String eventName;

  CustomerContact({
     this.name,
     this.company_role,
     this.email,
    required this.phone,
    required this.attendeeId,
    required this.eventID,
    required this.eventName
  });

  factory CustomerContact.fromCsv({required List<dynamic> csvRow, required int attendeeId, required int eventID, required String eventName}) {
    return CustomerContact(
      name: csvRow[0]?? "unspecified",
      company_role: csvRow[1]?? "unspecified",
      email: csvRow[2]?? "unspecified",
      phone: csvRow[3]?? "unspecified",
      attendeeId: attendeeId,
      eventID: eventID,
      eventName: eventName
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name?? "unspecified",
      'company_role': company_role?? "unspecified",
      'email': email?? "unspecified",
      'phone': phone?? "unspecified",
      'attendeeId': attendeeId,
      'eventID': eventID,
      'eventName': eventName,
    };
  }
}