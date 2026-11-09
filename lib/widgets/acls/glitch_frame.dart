import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ACLS brand accents, sampled from the ACLS theme art.
const kAclsTeal = Color(0xFF1FB5C8);
const kAclsGold = Color(0xFFE8B931);

/// One frame of a "signal interference" fight between two pictures.
///
/// [incumbent] is what the screen normally shows and [challenger] is what is
/// breaking through. [intensity] (0..1) sets how violent the interference is:
/// RGB split, displaced horizontal slices, scanlines and noise blocks.
/// [challengerShare] (0..1) is how much of the frame the challenger owns: it
/// picks the base picture and what each slice shows. [seed] fixes the random
/// layout. Change it every few frames for jitter, not every frame, or it
/// reads as noise rather than a glitch.
///
/// Pure widgets with no shaders or packages: both pictures are ordinary
/// widgets (usually [Image]s of already-decoded assets), so this is cheap
/// enough to animate for a few seconds.
class GlitchFrame extends StatelessWidget {
  const GlitchFrame({
    super.key,
    required this.incumbent,
    required this.challenger,
    required this.intensity,
    required this.challengerShare,
    required this.seed,
  });

  final Widget incumbent;
  final Widget challenger;
  final double intensity;
  final double challengerShare;
  final int seed;

  static const _redOnly = ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, //
    0, 0, 0, 1, 0,
  ]);
  static const _cyanOnly = ColorFilter.matrix(<double>[
    0, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(seed);
    final share = challengerShare.clamp(0.0, 1.0);
    Widget pick() => rng.nextDouble() < share ? challenger : incumbent;
    final base = pick();
    final k = intensity.clamp(0.0, 1.0);
    if (k <= 0.001) return base;

    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth.isFinite ? box.maxWidth : 400.0;
      final h = box.maxHeight.isFinite ? box.maxHeight : 300.0;
      final split = 2 + 10 * k;

      final layers = <Widget>[
        Positioned.fill(child: base),
        // Chromatic aberration: red and cyan ghosts pulled apart.
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(-split, 0),
            child: Opacity(
              opacity: 0.35 * k,
              child: ColorFiltered(colorFilter: _redOnly, child: base),
            ),
          ),
        ),
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(split, 0),
            child: Opacity(
              opacity: 0.35 * k,
              child: ColorFiltered(colorFilter: _cyanOnly, child: base),
            ),
          ),
        ),
      ];

      // Torn horizontal slices, each showing either picture, shifted sideways.
      final slices = 2 + (k * 9).round();
      for (var i = 0; i < slices; i++) {
        final top = rng.nextDouble();
        final height = 0.015 + rng.nextDouble() * 0.11 * (0.4 + k);
        final dx = (rng.nextDouble() - 0.5) * w * 0.18 * k;
        final content = pick();
        layers.add(Positioned.fill(
          child: ClipRect(
            clipper: _BandClipper(top, height),
            child: Transform.translate(
              offset: Offset(dx, 0),
              child: content,
            ),
          ),
        ));
      }

      layers.add(Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _InterferencePainter(
              intensity: k,
              seed: seed,
              size: Size(w, h),
            ),
          ),
        ),
      ));

      return ClipRect(child: Stack(fit: StackFit.expand, children: layers));
    });
  }
}

class _BandClipper extends CustomClipper<Rect> {
  _BandClipper(this.top, this.height);
  final double top;
  final double height;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(
      0, top * size.height, size.width, height * size.height);

  @override
  bool shouldReclip(_BandClipper old) =>
      old.top != top || old.height != height;
}

/// Scanlines, a few bright noise blocks in the brand colours and a rolling
/// tracking bar.
class _InterferencePainter extends CustomPainter {
  _InterferencePainter({
    required this.intensity,
    required this.seed,
    required this.size,
  });

  final double intensity;
  final int seed;
  final Size size;

  @override
  void paint(Canvas canvas, Size _) {
    final rng = math.Random(seed * 31 + 7);
    final scan = Paint()
      ..color = Colors.black.withValues(alpha: 0.18 * intensity);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), scan);
    }

    final bar = Paint()
      ..color = Colors.white.withValues(alpha: 0.06 + 0.10 * intensity);
    final barY = rng.nextDouble() * size.height;
    canvas.drawRect(
        Rect.fromLTWH(0, barY, size.width, 6 + 18 * rng.nextDouble()), bar);

    const colours = [kAclsTeal, kAclsGold, Colors.white, Color(0xFF7B2FF7)];
    final blocks = (intensity * 14).round();
    for (var i = 0; i < blocks; i++) {
      final paint = Paint()
        ..color = colours[rng.nextInt(colours.length)]
            .withValues(alpha: 0.25 + 0.5 * rng.nextDouble());
      canvas.drawRect(
        Rect.fromLTWH(
          rng.nextDouble() * size.width,
          rng.nextDouble() * size.height,
          8 + rng.nextDouble() * 60 * intensity,
          2 + rng.nextDouble() * 6,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_InterferencePainter old) =>
      old.seed != seed || old.intensity != intensity || old.size != size;
}
