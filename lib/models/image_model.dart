class ImageModel {
  final String sourceUrl;

  ImageModel({required this.sourceUrl});

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      sourceUrl: json['photo'],
    );
  }
}
