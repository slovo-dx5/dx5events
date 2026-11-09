import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/active_event/active_event.dart';
import '../../services/active_event/active_event_service.dart';
import 'acls_links.dart';
import 'glitch_frame.dart';

/// "Signal Hijack": the full-screen intro on the companion event's day. CIO100
/// is on air, interference builds, ACLS fights through in torn slices and
/// takes the screen. It ends on an ACLS card with "Explore ACLS" and
/// "Continue to CIO100", so the main event is always one tap away.
///
/// Shown once per device per day ([maybeShow]). Tap during the glitch to
/// skip to the end. With reduced motion it is a plain crossfade.
class SignalHijackOverlay extends StatefulWidget {
  const SignalHijackOverlay({super.key});

  static bool _showing = false;

  /// Demo mode: replay once per app launch instead of once per day.
  static bool _shownThisLaunch = false;

  /// Shows the intro if today is the companion's day and this device hasn't
  /// seen it today. Safe to call repeatedly.
  static Future<void> maybeShow(BuildContext context) async {
    final service = ActiveEventService.instance;
    final companion = service.companion;
    if (_showing || companion == null || !service.isCompanionDay) return;

    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    final key = 'acls_hijack_seen_${companion.id}_'
        '${now.year}-${now.month}-${now.day}';
    try {
      final prefs = await SharedPreferences.getInstance();
      if (ActiveEventService.kAclsDemoMode
          ? _shownThisLaunch
          : (prefs.getBool(key) ?? false)) {
        return;
      }
      if (!context.mounted || _showing) return;
      _showing = true;
      // Decode both pictures first so the fight doesn't start on a blank.
      await Future.wait([
        precacheImage(const AssetImage(ActiveEvent.aclsCardImage), context),
        precacheImage(const AssetImage(ActiveEvent.bundledCardImage), context),
      ]);
      if (!context.mounted) {
        _showing = false;
        return;
      }
      final navigator = Navigator.of(context, rootNavigator: true);
      await prefs.setBool(key, true);
      _shownThisLaunch = true;
      await navigator.push(PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 150),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => const SignalHijackOverlay(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ));
    } catch (e) {
      debugPrint('SignalHijack: skipped ($e)');
    } finally {
      _showing = false;
    }
  }

  @override
  State<SignalHijackOverlay> createState() => _SignalHijackOverlayState();
}

class _SignalHijackOverlayState extends State<SignalHijackOverlay>
    with SingleTickerProviderStateMixin {
  // Timeline in ms: CIO100 steady, interference builds, flash cut, settled.
  static const _total = 2600.0;
  static const _glitchStart = 400.0;
  static const _cut = 2000.0;
  static const _settled = 2200.0;
  static const _hapticsAt = [400.0, 900.0, 1350.0, 1700.0, 1900.0, 2000.0];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..addListener(_onTick);
  int _hapticIndex = 0;

  static const _cio = Image(
    image: AssetImage(ActiveEvent.bundledCardImage),
    fit: BoxFit.cover,
    gaplessPlayback: true,
  );
  // Whole poster, never cropped: phones are taller than its 9:16, so it sits
  // full-width under the status bar on its own black background, leaving the
  // spare height at the bottom for the ACLS card. Opaque, so its slices fully
  // cover CIO100 during the glitch.
  static const _acls = ColoredBox(
    color: Colors.black,
    child: SafeArea(
      bottom: false,
      child: Image(
        image: AssetImage(ActiveEvent.aclsCardImage),
        fit: BoxFit.contain,
        alignment: Alignment.topCenter,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
      ),
    ),
  );

  double get _ms => _c.value * _total;
  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _c.forward());
  }

  void _onTick() {
    if (_reduceMotion) return;
    while (_hapticIndex < _hapticsAt.length && _ms >= _hapticsAt[_hapticIndex]) {
      _hapticIndex == _hapticsAt.length - 1
          ? HapticFeedback.heavyImpact()
          : HapticFeedback.selectionClick();
      _hapticIndex++;
    }
  }

  void _skip() {
    if (_ms < _settled) {
      _hapticIndex = _hapticsAt.length;
      _c.value = _settled / _total;
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _picture() {
    final t = _ms;
    if (_reduceMotion) {
      final p = ((t - _glitchStart) / (_cut - _glitchStart)).clamp(0.0, 1.0);
      return Stack(fit: StackFit.expand, children: [
        _cio,
        Opacity(opacity: p, child: _acls),
      ]);
    }
    if (t >= _cut) return _acls;
    if (t < _glitchStart) {
      return GlitchFrame(
        incumbent: _cio,
        challenger: _acls,
        intensity: 0.06,
        challengerShare: 0,
        seed: (t / 90).floor(),
      );
    }
    final p = (t - _glitchStart) / (_cut - _glitchStart);
    final seed = (t / 70).floor();
    // Spikes: every few buckets the interference jumps to full.
    final spike = seed % 5 == 0 ? 0.35 : 0.0;
    return GlitchFrame(
      incumbent: _cio,
      challenger: _acls,
      intensity: (0.25 + 0.75 * p + spike).clamp(0.0, 1.0),
      challengerShare: (p * 0.9 + (seed % 3 == 0 ? 0.15 : 0)).clamp(0.0, 1.0),
      seed: seed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _skip,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _ms;
              final settled = t >= _settled;
              final flash =
                  t >= _cut && t < _settled ? 1 - (t - _cut) / (_settled - _cut) : 0.0;
              return Stack(fit: StackFit.expand, children: [
                _picture(),
                if (flash > 0)
                  IgnorePointer(
                    child: ColoredBox(
                        color: Colors.white.withValues(alpha: 0.85 * flash)),
                  ),
                if (!settled) _signalTag(t),
                if (!settled)
                  const Positioned(
                    right: 16,
                    bottom: 24,
                    child: SafeArea(
                      child: Text('Tap to skip',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ),
                  ),
                if (settled) _settledCard(((t - _settled) / 300).clamp(0.0, 1.0)),
              ]);
            },
          ),
        ),
      ),
    );
  }

  /// Top-left broadcast tag that flickers once the interference starts.
  Widget _signalTag(double t) {
    final interfering = t >= _glitchStart && (t / 110).floor() % 3 != 0;
    return Positioned(
      left: 16,
      top: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.black.withValues(alpha: 0.55),
            child: Text(
              interfering ? '▒ SIGNAL INTERFERENCE ▒' : '● CIO100 · LIVE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                color: interfering ? kAclsTeal : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _settledCard(double appear) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Opacity(
        opacity: appear,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - appear)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0),
                  Colors.black.withValues(alpha: 0.92),
                  Colors.black,
                ],
                stops: const [0, 0.3, 1],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '◉ SIGNAL HIJACKED',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: kAclsTeal,
                      fontSize: 13,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    ActiveEvent.aclsTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Live today, alongside CIO100 Day 3.',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAclsGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final nav = Navigator.of(context);
                        final companion = ActiveEventService.instance.companion;
                        nav.pop();
                        if (companion != null) {
                          nav.push(MaterialPageRoute(
                              builder: (_) => companionAgendaScreen(companion)));
                        }
                      },
                      child: const Text('Explore ACLS',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Continue to CIO100',
                          style: TextStyle(color: Colors.white, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
