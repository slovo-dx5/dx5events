import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/active_event/active_event.dart';
import 'glitch_frame.dart';

/// Home hero on the companion event's day: CIO100 and ACLS take turns on the
/// banner, swapping through a short glitch every few seconds, with equal
/// airtime so neither overshadows the other. It opens on ACLS, picking up
/// where the Signal Hijack intro left off.
///
/// Tapping while ACLS is on screen calls [onAclsTap] (opens its agenda).
class ShowdownHero extends StatefulWidget {
  const ShowdownHero({
    super.key,
    required this.cio,
    required this.cioLabel,
    required this.onAclsTap,
    this.aspectRatio = 1920 / 1047,
  });

  /// The usual CIO100 cover (an EventImage, so Directus art still wins).
  final Widget cio;
  final String cioLabel;
  final VoidCallback onAclsTap;
  final double aspectRatio;

  @override
  State<ShowdownHero> createState() => _ShowdownHeroState();
}

class _ShowdownHeroState extends State<ShowdownHero>
    with SingleTickerProviderStateMixin {
  static const _dwell = Duration(seconds: 5);

  late final AnimationController _swap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _showingAcls = !_showingAcls);
        _swap.value = 0;
      }
    });
  Timer? _timer;
  bool _showingAcls = true;

  static const _acls = Image(
    image: AssetImage(ActiveEvent.aclsCoverImage),
    fit: BoxFit.cover,
    gaplessPlayback: true,
  );

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_dwell, (_) {
      // Only swap while the home screen is actually on top.
      if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
      if (MediaQuery.of(context).disableAnimations) {
        setState(() => _showingAcls = !_showingAcls);
      } else if (!_swap.isAnimating) {
        _swap.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _swap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cio = SizedBox.expand(child: widget.cio);
    final current = _showingAcls ? _acls : cio;
    final next = _showingAcls ? cio : _acls;

    return GestureDetector(
      onTap: _showingAcls ? widget.onAclsTap : null,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Stack(fit: StackFit.expand, children: [
          AnimatedBuilder(
            animation: _swap,
            builder: (context, _) {
              final v = _swap.value;
              if (v == 0) {
                return AnimatedSwitcher(
                  duration: MediaQuery.of(context).disableAnimations
                      ? const Duration(milliseconds: 400)
                      : Duration.zero,
                  child: KeyedSubtree(
                      key: ValueKey(_showingAcls), child: current),
                );
              }
              return GlitchFrame(
                incumbent: current,
                challenger: next,
                intensity: math.sin(math.pi * v),
                challengerShare: v,
                seed: (v * 9).floor(),
              );
            },
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: _label(),
          ),
          Positioned(
            right: 12,
            bottom: 14,
            child: Row(children: [
              _dot(!_showingAcls, Colors.white),
              const SizedBox(width: 5),
              _dot(_showingAcls, kAclsTeal),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _label() {
    final acls = _showingAcls;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: (acls ? kAclsTeal : Colors.white).withValues(alpha: 0.6)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: acls ? kAclsGold : Colors.redAccent),
        const SizedBox(width: 6),
        Text(
          acls ? 'ACLS · TODAY' : widget.cioLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (acls) ...[
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 14, color: Colors.white),
        ],
      ]),
    );
  }

  Widget _dot(bool active, Color colour) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: active ? 16 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: active ? colour : Colors.white38,
          borderRadius: BorderRadius.circular(3),
        ),
      );
}
