
class AppSponsorData {
  int id;
  String phone_number;
  int  event_id;
  String  Sponsor_name;


  AppSponsorData({
    required this.id,
    required this.phone_number,
    required this.event_id,
    required this.Sponsor_name,
  });

  factory AppSponsorData.fromJson(Map<String, dynamic> json) => AppSponsorData(
    id: json['id'],

    phone_number: json['phone_number'],
    Sponsor_name: json['Sponsor_name'],
    event_id: json['event_id'],

  );

  Map<String, dynamic> toJson() => {
    'id': id,

    'phone_number': phone_number,
    'Sponsor_name': Sponsor_name,
    'event_id': event_id,

  };
}