class UserContact {
  final String firstName;
  final String lastName;
  final String email;
  final String company;
  final String role;
  final String phoneNumber;

  UserContact({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.company,
    required this.role,
    required this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'company': company,
      'role': role,
      'phoneNumber': phoneNumber,
    };
  }

  factory UserContact.fromMap(Map<String, dynamic> map) {
    return UserContact(
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      company: map['company'],
      role: map['role'],
      phoneNumber: map['phoneNumber'],
    );
  }
}
