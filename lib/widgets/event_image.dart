import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Event artwork from Directus when [url] is set, otherwise (and while it
/// loads or if it fails) the bundled [fallbackAsset].
class EventImage extends StatelessWidget {
  final String? url;
  final String fallbackAsset;
  final BoxFit fit;
  final double? width;
  final double? height;

  const EventImage({
    super.key,
    required this.url,
    required this.fallbackAsset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bundled = Image.asset(fallbackAsset,
        fit: fit, width: width, height: height);
    if (url == null || url!.isEmpty) return bundled;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => bundled,
      errorWidget: (_, __, ___) => bundled,
    );
  }
}
