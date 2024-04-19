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
  String? transparent_Logo;
  String? about;
  String? website;
  String? partnerName;

  PartnerData({
    this.id,

    this.logo,this.transparent_Logo,
    this.about,
    this.website,
    this.partnerName,
  });

  factory PartnerData.fromJson(Map<String, dynamic> json) => PartnerData(
    id: json['id'],

    logo: json['logo'],
    transparent_Logo: json['transparent_Logo'],
    about: json['about'],
    website: json['website'] ,
    partnerName: json['partner_name'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,

    'logo': logo,
    'transparent_Logo': transparent_Logo,
    'about': about,
    'website': website,
    'partner_name': partnerName,
  };
}


