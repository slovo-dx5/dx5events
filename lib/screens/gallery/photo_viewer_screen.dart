import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
// Import only the function we need — the package re-exports package:path,
// whose top-level `context` symbol otherwise collides with BuildContext.
import 'package:downloadsfolder/downloadsfolder.dart'
    show copyFileIntoDownloadFolder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';

import 'caption_overlay.dart';
import 'gallery_repository.dart';

/// Resolves a photo that only carries a thumbnail into its full record.
/// See [PhotoViewerScreen.resolveFullPhoto].
typedef FullPhotoResolver = Future<GalleryPhoto?> Function(GalleryPhoto photo);

/// Full-screen, swipeable, zoomable viewer for event photos with a real
/// "save to Downloads" action.
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    Key? key,
    required this.photos,
    required this.initialIndex,
    this.heroPrefix = '',
    this.resolveFullPhoto,
  }) : super(key: key);

  final List<GalleryPhoto> photos;
  final int initialIndex;

  /// Prefix for the Hero tags, matching whichever grid pushed this route —
  /// the same photo can appear in more than one grid, and duplicate tags on
  /// screen at once break the flight animation.
  final String heroPrefix;

  /// Upgrades a [GalleryPhoto.isThumbnailOnly] photo to the full record.
  ///
  /// Face search hands back only a signed thumbnail per match, which is fine
  /// for its grid but not for full-screen or for saving. When this is supplied
  /// the viewer resolves the current photo (and its neighbours) in the
  /// background and swaps the better variants in as they arrive.
  final FullPhotoResolver? resolveFullPhoto;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  bool _saving = false;

  /// Local copy, because entries get swapped for their resolved full records.
  late final List<GalleryPhoto> _photos = [...widget.photos];

  /// In-flight lookups by photo id. Keyed futures rather than a flag set so a
  /// second caller — a swipe back, or a download tapped mid-prefetch — joins
  /// the running lookup instead of starting another or racing past it.
  final Map<String, Future<void>> _resolving = {};

  /// Ids that resolution has already failed for — retrying on every swipe
  /// would hammer the endpoint for a photo that isn't coming back.
  final Set<String> _unresolvable = {};

  @override
  void initState() {
    super.initState();
    _resolveAround(_index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Resolves the current photo first, then its immediate neighbours, so a
  /// swipe usually lands on something already upgraded.
  void _resolveAround(int index) {
    for (final i in [index, index + 1, index - 1]) {
      if (i >= 0 && i < _photos.length) _resolve(i);
    }
  }

  Future<void> _resolve(int i) {
    final resolver = widget.resolveFullPhoto;
    final photo = _photos[i];
    if (resolver == null ||
        !photo.isThumbnailOnly ||
        _unresolvable.contains(photo.id)) {
      return Future<void>.value();
    }
    return _resolving.putIfAbsent(photo.id, () => _lookUp(photo, resolver));
  }

  Future<void> _lookUp(GalleryPhoto photo, FullPhotoResolver resolver) async {
    try {
      final full = await resolver(photo);
      if (!mounted) return;
      if (full == null) {
        // Keep showing the thumbnail — a missing full record is a degraded
        // render, not an error worth interrupting the user over.
        setState(() => _unresolvable.add(photo.id));
        return;
      }
      setState(() {
        // Re-find by id: nothing reorders this list today, but resolution is
        // async and an index captured earlier is the fragile way to write it.
        final at = _photos.indexWhere((p) => p.id == full.id);
        if (at != -1) _photos[at] = full;
      });
    } catch (e) {
      debugPrint('[PhotoViewer] resolve failed for ${photo.id}: $e');
      if (mounted) setState(() => _unresolvable.add(photo.id));
    } finally {
      _resolving.remove(photo.id);
    }
  }

  /// Whether the photo on screen is still only a thumbnail with a lookup in
  /// flight — drives the "loading full photo" hint.
  bool get _upgrading =>
      _photos[_index].isThumbnailOnly &&
      _resolving.containsKey(_photos[_index].id);

  Future<void> _download() async {
    if (_saving) return;
    setState(() => _saving = true);
    // Saving a face-search match must not write out the thumbnail, so make
    // sure the full record has landed before picking a variant.
    await _resolve(_index);
    if (!mounted) return;
    final photo = _photos[_index];
    final messenger = ScaffoldMessenger.of(context);
    try {
      // On older Android (< 29) writing to Downloads needs storage permission;
      // on newer versions the plugin uses MediaStore and this is a no-op.
      if (Platform.isAndroid) {
        await Permission.storage.request();
      }

      final List<int> bytes;
      final String fileName;
      if (photo.isAsset) {
        final data = await rootBundle.load(photo.assetPath!);
        bytes = data.buffer.asUint8List();
        fileName = 'dx5ve_${photo.assetPath!.split('/').last}';
      } else {
        // Best quality for save/export: xlarge, or the closest that exists.
        final variant =
            photo.variantFor(const ['xlarge', 'large', 'medium', 'small']);
        if (variant == null) throw Exception('no variant available');
        final res = await Dio().get<List<int>>(
          variant.url,
          options: Options(responseType: ResponseType.bytes),
        );
        bytes = res.data!;
        fileName = 'dx5ve_${photo.id}.${photo.fileExtension}';
      }
      final tmp = File('${Directory.systemTemp.path}/$fileName');
      await tmp.writeAsBytes(bytes);

      final ok = await copyFileIntoDownloadFolder(tmp.path, fileName);
      messenger.showSnackBar(SnackBar(
        content: Text(ok == true
            ? 'Saved "$fileName" to Downloads'
            : 'Could not save the photo.'),
      ));
    } catch (e) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Download failed: this photo is not available yet.'),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _image(GalleryPhoto photo) {
    if (photo.isAsset) {
      return Image.asset(
        photo.assetPath!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(
          GalleryRepository.placeholder,
          width: 120,
          color: Colors.white24,
        ),
      );
    }
    // Full resolution first: this view pinch-zooms to 4x, which is exactly the
    // case the guide reserves `xlarge` for. A face-search match supplies its
    // own xlarge URL, so this resolves without a lookup by photo id. The
    // grid's thumb stays visible via the cache while the bigger variant
    // streams in.
    final variant =
        photo.variantFor(const ['xlarge', 'large', 'medium', 'small']);
    if (variant == null) {
      return Image.asset(
        GalleryRepository.placeholder,
        width: 120,
        color: Colors.white24,
      );
    }
    return CachedNetworkImage(
      imageUrl: variant.url,
      cacheKey: '${photo.id}-${variant.label}',
      fit: BoxFit.contain,
      // A full-size photo over event wifi is a real wait, so show how much of
      // it has arrived rather than an indeterminate spinner.
      progressIndicatorBuilder: (_, __, progress) =>
          _LoadingPhoto(photo: photo, progress: progress),
      errorWidget: (_, __, ___) => Image.asset(
        GalleryRepository.placeholder,
        width: 120,
        color: Colors.white24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caption = _photos[_index].caption;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${_photos.length}',
            style: const TextStyle(fontSize: 15)),
        actions: [
          IconButton(
            tooltip: 'Save to Downloads',
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded),
            onPressed: _saving ? null : _download,
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _photos.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _resolveAround(i);
            },
            itemBuilder: (_, i) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Hero(
                    tag: '${widget.heroPrefix}${_photos[i].id}',
                    child: _image(_photos[i]),
                  ),
                ),
              );
            },
          ),
          // While only the thumbnail is on screen it looks soft — say why,
          // rather than letting it read as a bad photo.
          if (_upgrading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 64,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.6, color: Colors.white70),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Loading full photo…',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // The grid only shows a clipped caption; this is where the full
          // text lives, keyed so a swipe rebuilds it collapsed.
          if (caption != null && caption.trim().isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FullCaptionPanel(
                key: ValueKey(_photos[_index].id),
                caption: caption,
              ),
            ),
        ],
      ),
    );
  }
}

/// What fills the frame while the full-size photo downloads.
///
/// Two things the bare spinner couldn't do: it shows the grid's thumbnail —
/// already in the image cache, so it paints immediately — blurred up to fill
/// the frame, and it reports actual download progress. The blur is deliberate:
/// a 240px thumb stretched to full screen looks like a broken render
/// otherwise, where a blurred one reads as "still loading".
class _LoadingPhoto extends StatelessWidget {
  const _LoadingPhoto({Key? key, required this.photo, required this.progress})
      : super(key: key);

  final GalleryPhoto photo;
  final DownloadProgress progress;

  @override
  Widget build(BuildContext context) {
    final thumb = photo.variantFor(const ['thumb', 'small']);
    // Null whenever the server didn't send a content length, which is what
    // drives the indeterminate fallback below.
    final fraction = progress.progress;

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumb != null)
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: CachedNetworkImage(
                imageUrl: thumb.url,
                cacheKey: '${photo.id}-${thumb.label}',
                fit: BoxFit.cover,
                // No indicator here — this *is* the placeholder.
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          // Keeps the readout legible over a bright photo.
          Container(color: Colors.black.withOpacity(0.35)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 62,
                  height: 62,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: fraction,
                          strokeWidth: 3,
                          backgroundColor: Colors.white24,
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      if (fraction != null)
                        Text(
                          '${(fraction * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// `1.2 MB of 4.8 MB`, or just the downloaded size when the server didn't
  /// tell us the total.
  String get _label {
    final total = progress.totalSize;
    final downloaded = _bytes(progress.downloaded);
    return total == null
        ? 'Loading photo — $downloaded'
        : '$downloaded of ${_bytes(total)}';
  }

  static String _bytes(int value) {
    if (value < 1024) return '$value B';
    if (value < 1024 * 1024) return '${(value / 1024).toStringAsFixed(0)} KB';
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
