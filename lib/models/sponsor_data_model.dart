class RootSponsorDataModel {
  List<SponsorData>? data;

  RootSponsorDataModel({this.data});

  factory RootSponsorDataModel.fromJson(Map<String, dynamic> json) => RootSponsorDataModel(
    data: json['data'] != null ? List<SponsorData>.from(json['data'].map((x) => SponsorData.fromJson(x))) : null,
  );

  Map<String, dynamic> toJson() => {
    'data': data != null ? List<dynamic>.from(data!.map((x) => x.toJson())) : null,
  };
}

class SponsorData {
  int? id;
  DateTime? dateCreated;
  DateTime? dateUpdated;
  String? logo;
  String? about;
  List<Website>? websites;
  String? sponsorName;
  String? degree;

  SponsorData({
    this.id,
    this.dateCreated,
    this.dateUpdated,
    this.logo,
    this.about,
    this.websites,
    this.degree,
    this.sponsorName,
  });

  factory SponsorData.fromJson(Map<String, dynamic> json) => SponsorData(
    id: json['id'],
    dateCreated: json['date_created'] != null ? DateTime.parse(json['date_created']) : null,
    dateUpdated: json['date_updated'] != null ? DateTime.parse(json['date_updated']) : null,
    logo: json['logo'],
    about: json['about'],
    websites: json['websites'] != null ? List<Website>.from(json['websites'].map((x) => Website.fromJson(x))) : null,
    sponsorName: json['sponsor_name'],
    degree: json['degree'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date_created': dateCreated?.toIso8601String(),
    'date_updated': dateUpdated?.toIso8601String(),
    'logo': logo,
    'about': about,
    'websites': websites != null ? List<dynamic>.from(websites!.map((x) => x.toJson())) : null,
    'sponsor_name': sponsorName,
    'degree': degree,
  };
}

class Website {
  String? link;

  Website({this.link});

  factory Website.fromJson(Map<String, dynamic> json) => Website(
    link: json['link'],
  );

  Map<String, dynamic> toJson() => {
    'link': link,
  };
}
