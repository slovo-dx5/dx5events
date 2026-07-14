import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../providers/harry_controller.dart';
import '../breathing_animation.dart';
import 'harry_chat_panel.dart';

/// Hosts [HarryOverlay] inside its own persistent [Overlay].
///
/// Harry is injected as a sibling of the app's Navigator (via
/// `MaterialApp.router`'s `builder:`), so it has no Overlay ancestor of its
/// own. Tooltips, and the chat `TextField`'s selection/copy-paste toolbar,
/// both require an Overlay — without this they throw "No Overlay widget found".
/// The single entry is created once so drag position and chat state survive
/// rebuilds of the app builder.
class HarryRoot extends StatefulWidget {
  const HarryRoot({Key? key}) : super(key: key);

  @override
  State<HarryRoot> createState() => _HarryRootState();
}

class _HarryRootState extends State<HarryRoot> {
  late final List<OverlayEntry> _entries = [
    OverlayEntry(builder: (_) => const HarryOverlay()),
  ];

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: _entries);
}

/// The always-on, edge-draggable Harry bubble. Injected once at the
/// `MaterialApp.router` `builder:` level so it floats above every screen and
/// survives all navigation.
class HarryOverlay extends StatefulWidget {
  const HarryOverlay({Key? key}) : super(key: key);

  @override
  State<HarryOverlay> createState() => _HarryOverlayState();
}

class _HarryOverlayState extends State<HarryOverlay> {
  static const double _size = 56;
  static const double _margin = 12;
  static const String _kDx = 'harry_pos_dx';
  static const String _kDy = 'harry_pos_dy';

  Offset? _pos;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPosition();
  }

  Future<void> _loadSavedPosition() async {
    final dx = await getDoublePref(_kDx);
    final dy = await getDoublePref(_kDy);
    if (dx > 0 || dy > 0) {
      setState(() => _pos = Offset(dx, dy));
    }
  }

  Offset _defaultPos(Size screen, EdgeInsets pad) {
    return Offset(
      screen.width - _size - _margin,
      screen.height - _size - _margin - pad.bottom - 80,
    );
  }

  void _clampAndSet(Offset raw, Size screen, EdgeInsets pad) {
    final dx = raw.dx.clamp(_margin, screen.width - _size - _margin);
    final dy = raw.dy.clamp(
      pad.top + _margin,
      screen.height - _size - _margin - pad.bottom,
    );
    setState(() => _pos = Offset(dx.toDouble(), dy.toDouble()));
  }

  Future<void> _snapToEdge(Size screen) async {
    if (_pos == null) return;
    final center = _pos!.dx + _size / 2;
    final snappedX = center < screen.width / 2
        ? _margin
        : screen.width - _size - _margin;
    final snapped = Offset(snappedX, _pos!.dy);
    setState(() => _pos = snapped);
    await setDoublePref(key: _kDx, value: snapped.dx);
    await setDoublePref(key: _kDy, value: snapped.dy);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HarryController>();
    // Harry only appears inside an event (never on landing/login/OTP).
    if (!controller.inEvent) return const SizedBox.shrink();
    final media = MediaQuery.of(context);
    final screen = media.size;
    final pad = media.padding;
    final pos = _pos ??= _defaultPos(screen, pad);

    if (controller.isOpen) {
      return _panelLayer(controller, pad);
    }

    return Stack(
      children: [
        Positioned(
          left: pos.dx,
          top: pos.dy,
          child: GestureDetector(
            onTap: controller.open,
            onPanStart: (_) => setState(() => _dragging = true),
            onPanUpdate: (d) =>
                _clampAndSet(pos + d.delta, screen, pad),
            onPanEnd: (_) {
              setState(() => _dragging = false);
              _snapToEdge(screen);
            },
            child: _bubble(dragging: _dragging),
          ),
        ),
      ],
    );
  }

  Widget _panelLayer(HarryController controller, EdgeInsets pad) {
    // Lift the panel above the keyboard when it's open.
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return Stack(
      children: [
        // Tap-outside scrim to dismiss.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: controller.close,
            child: const SizedBox.shrink(),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: (keyboard > 0 ? keyboard : pad.bottom) + 16,
          child: HarryChatPanel(onClose: controller.close),
        ),
      ],
    );
  }

  Widget _bubble({required bool dragging}) {
    final avatar = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: kConnectedBlue, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/harry_hare.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    );

    // Gentle idle pulse when at rest; steady while being dragged.
    return dragging ? avatar : BreathingWidget(endScale: 1.08, child: avatar);
  }
}
