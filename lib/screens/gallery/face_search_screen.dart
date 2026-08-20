import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants.dart';
import 'caption_overlay.dart';
import 'gallery_repository.dart';
import 'photo_viewer_screen.dart';

/// "Find my photos" — the attendee submits a selfie and gets back the event
/// photos they appear in (`assets/face-search-api.pdf`).
///
/// Three things the API guide asks of the UI are enforced here:
///  - the submit path is disabled while a request is in flight (the endpoint
///    allows only 10 requests/minute per user);
///  - "no matches" is rendered as a valid outcome, visually distinct from an
///    error;
///  - the selfie is never copied anywhere — it goes straight from the picker,
///    through the cropper, into the request, and is not retained afterwards.
///
/// Picking is always followed by a crop step. The API picks whichever face it
/// is most confident about when a photo contains several, with no way for the
/// client to say which one is the user — so letting them crop down to their own
/// face is the only control we have over that.
class FaceSearchScreen extends StatefulWidget {
  const FaceSearchScreen({
    Key? key,
    required this.pixEventId,
    this.knownPhotos = const [],
  }) : super(key: key);

  /// Resolved pix event id whose gallery is searched.
  final String pixEventId;

  /// Photos already loaded by the gallery grid. A match only carries a single
  /// signed thumbnail, so any match found here is swapped for the full photo
  /// (whole variant ladder) to give the viewer something better to show.
  final List<GalleryPhoto> knownPhotos;

  @override
  State<FaceSearchScreen> createState() => _FaceSearchScreenState();
}

enum _Stage { intro, searching, results }

class _FaceSearchScreenState extends State<FaceSearchScreen> {
  final ImagePicker _picker = ImagePicker();

  _Stage _stage = _Stage.intro;
  FaceSearchStrictness _strictness = FaceSearchStrictness.normal;
  List<GalleryPhoto> _results = [];
  Map<String, int> _confidence = {};
  FaceSearchException? _error;

  bool get _busy => _stage == _Stage.searching;

  Future<void> _pickAndSearch(ImageSource source) async {
    if (_busy) return;
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        // Generous here so the cropper still has pixels to work with after the
        // user zooms into one face in a group shot; the crop step below does
        // the real size reduction.
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 92,
        preferredCameraDevice: CameraDevice.front,
      );
    } catch (e) {
      debugPrint('[FaceSearch] picker failed: $e');
    }
    if (picked == null || !mounted) return;

    final cropped = await _crop(picked.path);
    // Backing out of the cropper cancels the search rather than falling back
    // to the uncropped frame — the user chose not to send that photo.
    if (cropped == null || !mounted) return;

    await _search(File(cropped.path));
  }

  /// Square crop/zoom/rotate step between picking and searching.
  ///
  /// Locked to 1:1 because a face fills a square better than the source
  /// aspect ratio, and the 1600px/q88 output keeps a cropped selfie far below
  /// the endpoint's 15 MB cap. A cropper failure is non-fatal: it falls back
  /// to the picked file so the feature still works if the native view can't
  /// open.
  Future<CroppedFile?> _crop(String sourcePath) async {
    try {
      return await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        maxWidth: 1600,
        maxHeight: 1600,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 88,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop to your face',
            toolbarColor: kConnectedBlue,
            toolbarWidgetColor: Colors.white,
            // Light icons, to read against the blue toolbar.
            statusBarLight: false,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: kConnectedBlue,
            lockAspectRatio: true,
            // Rotate/scale controls stay available — a sideways photo is a
            // common reason detection fails.
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop to your face',
            doneButtonTitle: 'Use photo',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );
    } catch (e) {
      debugPrint('[FaceSearch] cropper failed, using the original: $e');
      return CroppedFile(sourcePath);
    }
  }

  Future<void> _search(File selfie) async {
    setState(() {
      _stage = _Stage.searching;
      _error = null;
    });
    try {
      final matches = await GalleryRepository.faceSearch(
        widget.pixEventId,
        selfie,
        strictness: _strictness,
      );
      if (!mounted) return;
      final known = {for (final p in widget.knownPhotos) p.id: p};
      setState(() {
        _results = [
          for (final m in matches) known[m.photoId] ?? m.toPhoto(),
        ];
        _confidence = {
          for (final m in matches) m.photoId: m.matchConfidencePercent,
        };
        _stage = _Stage.results;
      });
    } on FaceSearchException catch (e) {
      if (e.kind == FaceSearchError.notEnabled) {
        // No endpoint exposes the org flag — this 403 is the only signal, so
        // remember it and stop offering the feature for this event.
        GalleryRepository.markFaceSearchUnavailable(widget.pixEventId);
      }
      if (!mounted) return;
      setState(() {
        _error = e;
        _stage = _Stage.intro;
      });
    } catch (e) {
      debugPrint('[FaceSearch] unexpected error: $e');
      if (!mounted) return;
      setState(() {
        _error = const FaceSearchException(FaceSearchError.unknown);
        _stage = _Stage.intro;
      });
    }
  }

  void _startOver() {
    setState(() {
      _stage = _Stage.intro;
      _results = [];
      _confidence = {};
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldColor,
      appBar: AppBar(
        title: const Text('Find My Photos'),
        backgroundColor: kConnectedBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_stage == _Stage.results)
            TextButton(
              onPressed: _startOver,
              child: const Text('New search',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    switch (_stage) {
      case _Stage.searching:
        return _searchingView();
      case _Stage.results:
        return _resultsView();
      case _Stage.intro:
        return _introView();
    }
  }

  // -------------------------------------------------------------------- intro

  Widget _introView() {
    final error = _error;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: kConnectedBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.face_retouching_natural,
                  size: 48, color: kConnectedBlue),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Find yourself in the gallery',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Take a selfie and we'll look through the event photos for you. "
            "Your selfie is used for this one search only — it isn't saved by "
            "the app or by the gallery.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.grey.shade700,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 20),
            _errorBanner(error),
          ],
          const SizedBox(height: 28),
          _strictnessPicker(),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _busy ? null : () => _pickAndSearch(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_rounded),
            label: const Text('Take a selfie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kConnectedBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _pickAndSearch(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose an existing photo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kConnectedBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: kConnectedBlue.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline,
                  size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Works best with a well-lit photo of just you. If there are '
                  'other people in the shot, crop in on your own face — we '
                  "can't tell the search which face is yours.",
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(FaceSearchException error) {
    // "No clear face" is guidance, not a failure — a softer treatment makes
    // retaking the photo feel like the natural next step rather than a retry.
    final soft = error.kind == FaceSearchError.noFaceDetected;
    final color = soft ? kIconYellow : Colors.red.shade600;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(soft ? Icons.face_retouching_off : Icons.error_outline,
              size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error.message,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _strictnessPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOW CLOSE A MATCH?',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 10),
        for (final s in FaceSearchStrictness.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: _busy ? null : () => setState(() => _strictness = s),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _strictness == s
                        ? kConnectedBlue
                        : Colors.grey.shade300,
                    width: _strictness == s ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _strictness == s
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: _strictness == s
                          ? kConnectedBlue
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.label,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.blurb,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------- searching

  Widget _searchingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: kConnectedBlue),
            const SizedBox(height: 24),
            const Text(
              'Looking through the gallery…',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              "This takes a few seconds — we're comparing your photo against "
              'every face in the event.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ results

  Widget _resultsView() {
    if (_results.isEmpty) return _noMatchesView();
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.white,
          child: Text(
            _results.length == 1
                ? 'Found 1 photo that looks like you'
                : 'Found ${_results.length} photos that look like you',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: MasonryGridView.count(
            padding: const EdgeInsets.all(12),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemCount: _results.length,
            itemBuilder: (context, i) => _tile(i),
          ),
        ),
      ],
    );
  }

  Widget _noMatchesView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            const Text(
              'No matches found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              _strictness == FaceSearchStrictness.strict
                  ? 'Nothing matched closely enough. Try a looser match, or a '
                      'clearer selfie.'
                  : "We couldn't find you in the photos uploaded so far. More "
                      "are added throughout the event, so it's worth trying "
                      'again later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startOver,
              style: ElevatedButton.styleFrom(
                backgroundColor: kConnectedBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try another photo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(int i) {
    final photo = _results[i];
    final caption = photo.caption;
    return GestureDetector(
      onTap: () => PersistentNavBarNavigator.pushNewScreen(
        context,
        screen: PhotoViewerScreen(
          photos: _results,
          initialIndex: i,
          heroPrefix: 'face-',
          // A match only carries a signed thumbnail, so the viewer resolves
          // the full record by photo id before rendering full-screen. The
          // match's own `day` narrows the lookup to that day's photos.
          resolveFullPhoto: (photo) => GalleryRepository.resolveFullPhoto(
            widget.pixEventId,
            photo.id,
            day: photo.day,
          ),
        ),
        withNavBar: false,
        pageTransitionAnimation: PageTransitionAnimation.fade,
      ),
      child: Hero(
        // Prefixed so these tags can't collide with the main gallery's grid,
        // which may have the same photo on screen behind this route.
        tag: 'face-${photo.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              _tileImage(photo),
              if (_isStrongMatch(photo.id))
                Positioned(top: 8, left: 8, child: _strongMatchBadge()),
              if (caption != null && caption.trim().isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CaptionOverlay(caption: caption),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The score is explicitly a *relative* ranking, not a probability, so it
  /// surfaces as a qualitative badge rather than "87% chance this is you".
  bool _isStrongMatch(String photoId) => (_confidence[photoId] ?? 0) >= 80;

  Widget _strongMatchBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 13, color: Colors.amber),
          SizedBox(width: 4),
          Text(
            'Strong match',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tileImage(GalleryPhoto photo) {
    final variant = photo.variantFor(const ['thumb', 'small', 'medium']);
    if (variant == null) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: Colors.grey.shade300,
          alignment: Alignment.center,
          child: Image.asset(GalleryRepository.placeholder,
              width: 40, color: Colors.grey),
        ),
      );
    }
    return AspectRatio(
      // Matches carry no dimensions, so [GalleryPhoto.aspectRatio] gives a
      // square here; photos matched against the loaded grid keep their real
      // ratio.
      aspectRatio: photo.aspectRatio,
      child: CachedNetworkImage(
        imageUrl: variant.url,
        cacheKey: '${photo.id}-${variant.label}',
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(color: Colors.white),
        ),
        errorWidget: (_, __, ___) => Container(color: Colors.grey.shade300),
      ),
    );
  }
}
