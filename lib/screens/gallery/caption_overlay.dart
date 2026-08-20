import 'package:flutter/material.dart';

/// The truncated caption strip that sits along the bottom edge of a gallery
/// tile.
///
/// Grid tiles are small, so the caption is clipped to [maxLines] with an
/// ellipsis; the full text belongs to the full-screen viewer
/// ([FullCaptionPanel]). The gradient keeps light photos readable underneath
/// without boxing the image in a solid bar.
class CaptionOverlay extends StatelessWidget {
  const CaptionOverlay({
    Key? key,
    required this.caption,
    this.maxLines = 2,
    this.fontSize = 12,
  }) : super(key: key);

  final String caption;
  final int maxLines;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // Purely decorative — taps must reach the tile's own gesture handler so
      // the caption doesn't create a dead zone over the bottom of the photo.
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black87],
            stops: [0, 0.85],
          ),
        ),
        child: Text(
          caption.trim(),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            height: 1.3,
            shadows: const [
              Shadow(blurRadius: 3, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full caption, shown under a photo in the full-screen viewer.
///
/// The grid only ever shows a clipped version, so this is where the whole text
/// is available. Long captions would otherwise cover the photo, so it collapses
/// past [collapsedLines] and the reader taps "More" to expand it into a
/// height-capped scrollable panel.
class FullCaptionPanel extends StatefulWidget {
  const FullCaptionPanel({
    Key? key,
    required this.caption,
    this.collapsedLines = 3,
  }) : super(key: key);

  final String caption;
  final int collapsedLines;

  @override
  State<FullCaptionPanel> createState() => _FullCaptionPanelState();
}

class _FullCaptionPanelState extends State<FullCaptionPanel> {
  bool _expanded = false;

  @override
  void didUpdateWidget(FullCaptionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Swiping to another photo starts its caption collapsed again.
    if (oldWidget.caption != widget.caption && _expanded) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.caption.trim();
    const style = TextStyle(
      color: Colors.white,
      fontSize: 15,
      height: 1.4,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final overflows = _overflows(caption, style, constraints.maxWidth);
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
              stops: [0, 0.6],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                // Even expanded, the caption never takes more than a third of
                // the screen — the photo stays the subject.
                constraints: BoxConstraints(
                  maxHeight: _expanded
                      ? MediaQuery.of(context).size.height * 0.33
                      : double.infinity,
                ),
                child: SingleChildScrollView(
                  physics: _expanded
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: Text(
                    caption,
                    maxLines: _expanded ? null : widget.collapsedLines,
                    overflow: _expanded ? null : TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
              ),
              if (overflows)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _expanded ? 'Less' : 'More',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Whether [caption] needs more than [collapsedLines] at [width] — i.e.
  /// whether a More/Less toggle is worth showing at all.
  bool _overflows(String caption, TextStyle style, double width) {
    final painter = TextPainter(
      text: TextSpan(text: caption, style: style),
      maxLines: widget.collapsedLines,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: width);
    return painter.didExceedMaxLines;
  }
}
