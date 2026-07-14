import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../constants.dart';
import 'gallery_repository.dart';
import 'photo_viewer_screen.dart';

/// Event photo gallery — a masonry grid that keeps each photo's aspect ratio,
/// so portrait and landscape shots both display naturally (no square cropping).
/// Tap any photo to view full-screen and download it.
class EventGalleryScreen extends StatelessWidget {
  const EventGalleryScreen({Key? key, this.eventId}) : super(key: key);

  final String? eventId;

  @override
  Widget build(BuildContext context) {
    final photos = GalleryRepository.photos();

    return Scaffold(
      backgroundColor: kScaffoldColor,
      appBar: AppBar(
        title: const Text('Event Gallery'),
        backgroundColor: kConnectedBlue,
        foregroundColor: Colors.white,
      ),
      body: photos.isEmpty
          ? const Center(child: Text('No photos yet — check back soon.'))
          : MasonryGridView.count(
              padding: const EdgeInsets.all(12),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: photos.length,
              itemBuilder: (context, i) => _tile(context, photos, i),
            ),
    );
  }

  Widget _tile(BuildContext context, List<GalleryPhoto> photos, int i) {
    final photo = photos[i];
    return GestureDetector(
      onTap: () => PersistentNavBarNavigator.pushNewScreen(
        context,
        screen: PhotoViewerScreen(photos: photos, initialIndex: i),
        withNavBar: false,
        pageTransitionAnimation: PageTransitionAnimation.fade,
      ),
      child: Hero(
        tag: photo.assetPath,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // No fixed height/aspect ratio: the image lays out at its natural
              // aspect ratio within the column width, giving the masonry effect.
              Image.asset(
                photo.assetPath,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color: Colors.grey.shade300,
                    alignment: Alignment.center,
                    child: Image.asset(
                      GalleryRepository.placeholder,
                      width: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              if (photo.caption != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                    child: Text(
                      photo.caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
