class CustomerSpeaker {
  final String? first_name;
  final String? company;
  final String? email;
  final String? role;
  final String? bio;
  final String? photo;
  var phone;


  CustomerSpeaker({
    this.first_name,
    this.company,
    this.role,
    this.email,this.bio,
    this.photo,
    required this.phone,

  });

  factory CustomerSpeaker.fromCsv({required List<dynamic> csvRow, required int attendeeId, required int eventID, required String eventName}) {
    return CustomerSpeaker(
        first_name: csvRow[2]?? "unspecified",
        company: csvRow[4]?? "unspecified",
        role: csvRow[5]?? "unspecified",
        email: csvRow[9]?? "unspecified",
        phone: csvRow[8]?? "unspecified",
        bio: csvRow[11],
        photo: "",

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': first_name?? "unspecified",
      'role': role?? "unspecified",
      'company': company,
      'bio': bio,
      'email': email?? "unspecified",
      'phone': phone?? "unspecified",
      'photo': photo?? "unspecified",

    };
  }
}