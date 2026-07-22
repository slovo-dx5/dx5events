/// Models for the event gallery, mirroring the Event Image Service API
/// (`assets/mobile-gallery-api.md`).

class PhotoVariant {
  const PhotoVariant({
    required this.label,
    required this.width,
    required this.height,
    required this.url,
  });

  factory PhotoVariant.fromJson(Map<String, dynamic> json) => PhotoVariant(
        label: json['label'] as String,
        width: (json['width'] as num).toInt(),
        height: (json['height'] as num).toInt(),
        url: json['url'] as String,
      );

  final String label;
  final int width;
  final int height;

  /// Signed URL — expires in 1 hour, so never persist it. Use [GalleryPhoto.id]
  /// plus [label] as a stable cache key instead of the URL.
  final String url;
}

/// A single event photo — either a real API photo or (POC fallback, when the
/// API isn't configured) a bundled asset under `assets/images/gallery/`.
class GalleryPhoto {
  const GalleryPhoto({
    required this.id,
    this.assetPath,
    this.caption,
    this.altText,
    this.contentType,
    this.width,
    this.height,
    this.blurhash,
    this.day,
    this.sessionId,
    this.variants = const [],
  });

  const GalleryPhoto.asset(String path, {String? caption})
      : this(id: path, assetPath: path, caption: caption);

  factory GalleryPhoto.fromJson(Map<String, dynamic> json) => GalleryPhoto(
        id: json['id'] as String,
        caption: json['caption'] as String?,
        altText: json['altText'] as String?,
        contentType: json['contentType'] as String?,
        width: (json['width'] as num?)?.toInt(),
        height: (json['height'] as num?)?.toInt(),
        blurhash: json['blurhash'] as String?,
        day: json['day'] as String?,
        sessionId: json['sessionId'] as String?,
        variants: ((json['variants'] as List?) ?? const [])
            .map((v) => PhotoVariant.fromJson(Map<String, dynamic>.from(v)))
            .toList(),
      );

  final String id;
  final String? assetPath;
  final String? caption;
  final String? altText;
  final String? contentType;
  final int? width;
  final int? height;
  final String? blurhash;
  final String? day;
  final String? sessionId;
  final List<PhotoVariant> variants;

  bool get isAsset => assetPath != null;

  /// Natural aspect ratio, used to reserve grid space before the image loads.
  double get aspectRatio =>
      (width != null && height != null && height! > 0) ? width! / height! : 1.0;

  /// The variant for the first label in [preferred] that exists, falling back
  /// to the largest available one. Not every rung exists for small source
  /// images, so callers must treat labels as "closest that exists".
  PhotoVariant? variantFor(List<String> preferred) {
    if (variants.isEmpty) return null;
    for (final label in preferred) {
      for (final v in variants) {
        if (v.label == label) return v;
      }
    }
    return variants.reduce((a, b) => a.width >= b.width ? a : b);
  }

  /// File extension for downloads, derived from the content type.
  String get fileExtension {
    switch (contentType) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/gif':
        return 'gif';
      default:
        return 'jpg';
    }
  }
}

class GalleryDay {
  const GalleryDay({required this.day, required this.count});

  factory GalleryDay.fromJson(Map<String, dynamic> json) => GalleryDay(
        day: json['day'] as String,
        count: (json['count'] as num).toInt(),
      );

  /// `YYYY-MM-DD`, computed in the event's own timezone.
  final String day;
  final int count;
}

class GallerySession {
  const GallerySession({required this.id, required this.name});

  factory GallerySession.fromJson(Map<String, dynamic> json) =>
      GallerySession(id: json['id'] as String, name: json['name'] as String);

  final String id;
  final String name;
}

class PhotosPage {
  const PhotosPage({required this.photos, this.nextCursor});

  final List<GalleryPhoto> photos;

  /// Opaque keyset cursor; null when there are no more pages. Only valid for
  /// the `sort` it was issued under.
  final String? nextCursor;
}
