import 'dart:io';

// Import only the function we need — the package re-exports package:path,
// whose top-level `context` symbol otherwise collides with BuildContext.
import 'package:downloadsfolder/downloadsfolder.dart'
    show copyFileIntoDownloadFolder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';

import 'gallery_repository.dart';

/// Full-screen, swipeable, zoomable viewer for event photos with a real
/// "save to Downloads" action.
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    Key? key,
    required this.photos,
    required this.initialIndex,
  }) : super(key: key);

  final List<GalleryPhoto> photos;
  final int initialIndex;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    if (_saving) return;
    setState(() => _saving = true);
    final photo = widget.photos[_index];
    final messenger = ScaffoldMessenger.of(context);
    try {
      // On older Android (< 29) writing to Downloads needs storage permission;
      // on newer versions the plugin uses MediaStore and this is a no-op.
      if (Platform.isAndroid) {
        await Permission.storage.request();
      }

      final data = await rootBundle.load(photo.assetPath);
      final bytes = data.buffer.asUint8List();
      final fileName = 'dx5ve_${photo.assetPath.split('/').last}';
      final tmp = File('${Directory.systemTemp.path}/$fileName');
      await tmp.writeAsBytes(bytes);

      final ok = await copyFileIntoDownloadFolder(tmp.path, fileName);
      messenger.showSnackBar(SnackBar(
        content: Text(ok == true
            ? 'Saved "$fileName" to Downloads'
            : 'Could not save the photo.'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Download failed: this photo is not available yet.'),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.photos[_index].caption;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.photos.length}',
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
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.asset(
                    widget.photos[i].assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      GalleryRepository.placeholder,
                      width: 120,
                      color: Colors.white24,
                    ),
                  ),
                ),
              );
            },
          ),
          if (caption != null && caption.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Text(caption,
                    style: const TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ),
        ],
      ),
    );
  }
}
