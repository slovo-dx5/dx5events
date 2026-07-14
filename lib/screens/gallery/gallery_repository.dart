/// A single event photo. For the POC these point at bundled assets under
/// `assets/images/gallery/`. Drop real photos there with these names (g1.jpg …)
/// and they appear automatically; missing files fall back to a placeholder.
class GalleryPhoto {
  const GalleryPhoto({required this.assetPath, this.caption});
  final String assetPath;
  final String? caption;
}

/// Mock source of gallery photos.
///
/// TODO(backend): replace [photos] with a call that fetches this event's
/// photos by eventId (e.g. Directus `/items/event_photos?filter[event_id]=…`).
class GalleryRepository {
  static const String placeholder = 'assets/images/gallery/placeholder.png';

  static List<GalleryPhoto> photos() => const [
        GalleryPhoto(assetPath: 'assets/images/gallery/AfricaCISOSummit-0113.png'),
        GalleryPhoto(assetPath: 'assets/images/gallery/BFSI_DAY2SESSION-65.png'),
        GalleryPhoto(assetPath: 'assets/images/gallery/CAS-12.png'),
        GalleryPhoto(assetPath: 'assets/images/gallery/CIO_2026-22.png'),
        GalleryPhoto(assetPath: 'assets/images/gallery/CISO2_other-25.png'),
        GalleryPhoto(assetPath: 'assets/images/gallery/CISO_Other-167.png'),
        GalleryPhoto(assetPath: 'assets/images/gallery/ConnectedAfricaSummit2026(Day4)-111.jpg'),
        GalleryPhoto(assetPath: 'assets/images/gallery/ConnectedAfricaSummit2026(Day4)-114.jpg'),
        GalleryPhoto(assetPath: 'assets/images/gallery/ConnectedAfricaSummit2026(Day4)-122.jpg'),
        GalleryPhoto(assetPath: 'assets/images/gallery/ConnectedAfricaSummit2026DayivGalaDinner(241of261).jpg'),
        GalleryPhoto(assetPath: 'assets/images/gallery/DayiiiConnectedSummitKeyengagements-580.jpg'),
        GalleryPhoto(assetPath: 'assets/images/gallery/DayiiiConnectedSummitKeyengagements-613.jpg'),
        GalleryPhoto(assetPath: 'assets/images/gallery/Latt_2025-7.png'),
        GalleryPhoto(assetPath: 'assets/images/gallery/Latt_2025-78.png'),
        GalleryPhoto(assetPath: 'assets/images/gallery/S_CIO100DAY_3-321.png'),
        GalleryPhoto(assetPath: 'assets/images/gallery/TYA222026-11.png'),
        GalleryPhoto(assetPath: 'assets/images/gallery/TYA222026-16.png'),
      ];
}
