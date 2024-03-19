class RootPartnerDataModel {
  List<PartnerData>? data;

  RootPartnerDataModel({this.data});

  factory RootPartnerDataModel.fromJson(Map<String, dynamic> json) => RootPartnerDataModel(
    data: json['data'] != null ? List<PartnerData>.from(json['data'].map((x) => PartnerData.fromJson(x))) : null,
  );

  Map<String, dynamic> toJson() => {
    'data': data != null ? List<dynamic>.from(data!.map((x) => x.toJson())) : null,
  };
}

class PartnerData {
  int? id;

  String? logo;
  String? about;
  String? website;
  String? partnerName;

  PartnerData({
    this.id,

    this.logo,
    this.about,
    this.website,
    this.partnerName,
  });

  factory PartnerData.fromJson(Map<String, dynamic> json) => PartnerData(
    id: json['id'],

    logo: json['logo'],
    about: json['about'],
    website: json['website'] ,
    partnerName: json['partner_name'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,

    'logo': logo,
    'about': about,
    'website': website,
    'partner_name': partnerName,
  };
}


