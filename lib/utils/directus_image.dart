import '../dioServices/base_url.dart';

/// Helpers for building optimized Directus asset URLs.
///
/// Directus serves on-the-fly transforms from `/assets/{id}?...`, so the feed
/// can request small webp thumbnails instead of full-resolution originals and
/// only load the original when a photo is opened.
class DirectusImage {
  DirectusImage._();

  /// Sentinel stored on posts that have no image.
  static const String none = 'no image';

  static bool hasImage(String? assetId) =>
      assetId != null && assetId.isNotEmpty && assetId != none;

  /// A compressed thumbnail suitable for the feed (webp, cover-cropped).
  static String thumb(String assetId, {int width = 800, int quality = 70}) {
    return '${BaseURL.Baseurl}/assets/$assetId'
        '?width=$width&quality=$quality&format=webp&fit=cover';
  }

  /// A larger, higher-quality render for the full-screen viewer.
  static String full(String assetId, {int width = 1600, int quality = 85}) {
    return '${BaseURL.Baseurl}/assets/$assetId'
        '?width=$width&quality=$quality&format=webp';
  }

  /// A small square avatar render.
  static String avatar(String assetId, {int size = 160}) {
    return '${BaseURL.Baseurl}/assets/$assetId'
        '?width=$size&height=$size&quality=75&format=webp&fit=cover';
  }
}
