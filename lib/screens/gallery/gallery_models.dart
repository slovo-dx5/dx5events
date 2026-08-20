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

  /// Whether a specific variant rung was returned for this photo.
  ///
  /// Unlike [variantFor], this never falls back — callers use it to ask "do I
  /// actually have a full-size rung, or only the thumbnail?", which is how a
  /// face-search result (thumbnail only) is told apart from a gallery photo.
  bool hasVariant(String label) => variants.any((v) => v.label == label);

  /// True when this photo carries nothing better than a thumbnail, and so
  /// needs resolving against the photos endpoint before a full-size render.
  bool get isThumbnailOnly =>
      !isAsset &&
      !hasVariant('medium') &&
      !hasVariant('large') &&
      !hasVariant('xlarge');

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

// ---------------------------------------------------------------- face search

/// How confident the server must be before a photo counts as a match
/// (`strictness` query param on `POST /events/:id/face-search`).
enum FaceSearchStrictness { strict, normal, loose }

extension FaceSearchStrictnessX on FaceSearchStrictness {
  String get value => toString().split('.').last;

  String get label {
    switch (this) {
      case FaceSearchStrictness.strict:
        return 'Strict';
      case FaceSearchStrictness.loose:
        return 'Loose';
      case FaceSearchStrictness.normal:
        return 'Balanced';
    }
  }

  String get blurb {
    switch (this) {
      case FaceSearchStrictness.strict:
        return 'Fewer photos, but more likely to be you';
      case FaceSearchStrictness.loose:
        return 'More photos, but some may not be you';
      case FaceSearchStrictness.normal:
        return 'A good balance for most people';
    }
  }
}

/// One photo returned by the face search endpoint.
///
/// Note this is a *lighter* shape than [GalleryPhoto] — the API signs a
/// thumbnail and a full-size image, with no variant ladder in between and no
/// dimensions.
class FaceMatch {
  const FaceMatch({
    required this.photoId,
    required this.matchConfidencePercent,
    this.thumbnailUrl,
    this.fullImageUrl,
    this.caption,
    this.sessionId,
    this.sessionName,
    this.day,
  });

  factory FaceMatch.fromJson(Map<String, dynamic> json) => FaceMatch(
        photoId: json['photoId'] as String,
        matchConfidencePercent:
            (json['matchConfidencePercent'] as num?)?.toInt() ?? 0,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        fullImageUrl: json['fullImageUrl'] as String?,
        caption: json['caption'] as String?,
        sessionId: json['sessionId'] as String?,
        sessionName: json['sessionName'] as String?,
        day: json['day'] as String?,
      );

  final String photoId;

  /// 0–100 relative ranking score. Deliberately *not* surfaced as a
  /// probability in the UI (see the face search guide, §3).
  final int matchConfidencePercent;

  /// Temporary signed URL, expires in ~1 hour — never persist it.
  final String? thumbnailUrl;

  /// Full-size image for this match, so opening it needs no second lookup by
  /// [photoId]. Signed and short-lived just like [thumbnailUrl].
  ///
  /// Added to the endpoint after the original spec
  /// (`assets/face-search-api.pdf`) was written, so it stays optional: when
  /// it's absent the viewer falls back to resolving the photo by id against
  /// `GET /events/:id/photos`.
  final String? fullImageUrl;

  final String? caption;
  final String? sessionId;
  final String? sessionName;
  final String? day;

  /// Adapts a match into the shape the grid/viewer already know how to render.
  ///
  /// Both signed URLs become variants — `thumb` for the grid and `xlarge`
  /// for full-screen — so [GalleryPhoto.variantFor] picks between them exactly
  /// as it does for a gallery photo.
  ///
  /// `fullImageUrl` is labelled `xlarge` because it *is* the xlarge rendition:
  /// the same object the photos endpoint signs under that label. Sharing the
  /// label means both paths share the `<id>-xlarge` image cache entry, so a
  /// photo opened from face search and later from the gallery downloads once.
  /// Widths are recorded as 0 because the endpoint reports no pixel
  /// dimensions; selection here is always by label, and the tile falls back to
  /// a square ratio.
  GalleryPhoto toPhoto() => GalleryPhoto(
        id: photoId,
        caption: caption,
        day: day,
        sessionId: sessionId,
        variants: [
          if (thumbnailUrl != null)
            PhotoVariant(
              label: 'thumb',
              width: 0,
              height: 0,
              url: thumbnailUrl!,
            ),
          if (fullImageUrl != null)
            PhotoVariant(
              label: 'xlarge',
              width: 0,
              height: 0,
              url: fullImageUrl!,
            ),
        ],
      );
}

/// Why a face search could not produce results. Each case maps to distinct UI
/// copy — in particular [notEnabled] hides the entry point entirely, and
/// [noFaceDetected] asks the user to retake rather than reporting a failure.
enum FaceSearchError {
  /// 403 — the event's organization has face search turned off.
  notEnabled,

  /// 403/404 — no access to this event.
  noAccess,

  /// 400 — no image in the request (a client bug).
  missingImage,

  /// 422 — the file wasn't a readable image.
  unreadableImage,

  /// 422 — readable, but no clear face to search with.
  noFaceDetected,

  /// 429 — 10 requests/minute per user.
  rateLimited,

  /// 502 — face detection service down; safe to retry shortly.
  serviceUnavailable,

  /// Anything else (network, timeout, 5xx).
  unknown,
}

class FaceSearchException implements Exception {
  const FaceSearchException(this.kind, [this.detail]);

  final FaceSearchError kind;
  final String? detail;

  /// User-facing copy. "No matches" is deliberately absent — an empty result
  /// is a success, not an error.
  String get message {
    switch (kind) {
      case FaceSearchError.notEnabled:
        return 'Photo search isn\'t available for this event.';
      case FaceSearchError.noAccess:
        return 'This gallery isn\'t available to you right now.';
      case FaceSearchError.missingImage:
        return 'No photo was sent. Please pick a selfie and try again.';
      case FaceSearchError.unreadableImage:
        return 'That file couldn\'t be read as a photo. Try another one.';
      case FaceSearchError.noFaceDetected:
        return 'We couldn\'t find a clear face in that photo. Try again in '
            'better light, with your face filling more of the frame.';
      case FaceSearchError.rateLimited:
        return 'That\'s a lot of searches in a short time. Wait a minute and '
            'try again.';
      case FaceSearchError.serviceUnavailable:
        return 'Photo search is temporarily unavailable. Please try again in '
            'a moment.';
      case FaceSearchError.unknown:
        return 'Something went wrong searching for your photos. Check your '
            'connection and try again.';
    }
  }

  /// Whether offering a "Try again" button makes sense for this failure.
  bool get isRetryable =>
      kind != FaceSearchError.notEnabled && kind != FaceSearchError.noAccess;

  @override
  String toString() => 'FaceSearchException($kind, $detail)';
}
