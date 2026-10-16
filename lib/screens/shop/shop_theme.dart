import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';

/// Visual language for the shop: one palette, one set of radii and shadows,
/// and the small building blocks every shop screen shares, so the store reads
/// as one designed surface rather than six screens styled independently.
class ShopColors {
  ShopColors._();

  /// Headings, dark surfaces, the floating cart bar.
  static const ink = Color(0xFF0F1C2E);

  /// Secondary text.
  static const inkSoft = Color(0xFF5B6475);

  /// Page background.
  static const canvas = Color(0xFFF4F6FA);

  /// Behind product photos — light enough that any shot sits on it cleanly.
  static const tile = Color(0xFFEDF1F6);

  static const line = Color(0xFFE3E7EF);
  static const brand = kConnectedBlue;
  static const brandDeep = Color(0xFF1D5A88);
  static const accent = kGoldColor;
  static const success = Color(0xFF17A06B);
  static const danger = Color(0xFFE5484D);
  static const warning = Color(0xFFEF8A00);
}

class ShopGradients {
  ShopGradients._();

  static const brand = LinearGradient(
    colors: [ShopColors.brandDeep, ShopColors.brand],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// The shop header: night-sky ink into the brand blue.
  static const hero = LinearGradient(
    colors: [ShopColors.ink, ShopColors.brandDeep, ShopColors.brand],
    stops: [0, 0.55, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const photo = RadialGradient(
    colors: [Colors.white, ShopColors.tile],
    radius: 0.9,
  );
}

class ShopShadows {
  ShopShadows._();

  static final soft = [
    BoxShadow(
      color: ShopColors.ink.withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static final lifted = [
    BoxShadow(
      color: ShopColors.ink.withValues(alpha: 0.18),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];

  static final bar = [
    BoxShadow(
      color: ShopColors.ink.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, -6),
    ),
  ];
}

/// Small caps label above a heading ("BACKPACKS", "ORDER SUMMARY").
class ShopEyebrow extends StatelessWidget {
  const ShopEyebrow(this.text, {Key? key, this.color}) : super(key: key);
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: color ?? ShopColors.inkSoft,
      ),
    );
  }
}

/// Shrinks slightly while pressed — the tactile feel on cards and buttons.
class PressableScale extends StatefulWidget {
  const PressableScale({
    Key? key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  }) : super(key: key);

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool down) {
    if (widget.onTap == null || _down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// The shop's call to action: a gradient pill. Disabled turns flat grey;
/// [busy] swaps the label for a spinner without changing the button's size.
class ShopPrimaryButton extends StatelessWidget {
  const ShopPrimaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailing,
    this.busy = false,
    this.height = 56,
    this.color,
  }) : super(key: key);

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Right-aligned secondary text, e.g. the total.
  final String? trailing;
  final bool busy;
  final double height;

  /// Solid colour instead of the brand gradient (e.g. success green).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final decoration = BoxDecoration(
      gradient: enabled && color == null ? ShopGradients.brand : null,
      color: enabled ? color : ShopColors.line,
      borderRadius: BorderRadius.circular(height / 2),
      boxShadow: enabled
          ? [
              BoxShadow(
                color: (color ?? ShopColors.brand).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    );
    final fg = enabled ? Colors.white : ShopColors.inkSoft;

    return PressableScale(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onPressed!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        decoration: decoration,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: busy
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                ),
              )
            : _content(fg),
      ),
    );
  }
}

extension on ShopPrimaryButton {
  /// Icon + label (+ trailing text on the right). On a narrow phone the
  /// label scales down a touch rather than being cut to "Add t…".
  Widget _content(Color fg) {
    final main = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: trailing == null ? Alignment.center : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 10),
          ],
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: fg,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
    if (trailing == null) return Center(child: main);
    return Row(
      children: [
        Expanded(child: main),
        const SizedBox(width: 10),
        Text(
          trailing!,
          maxLines: 1,
          style: TextStyle(
            color: fg.withValues(alpha: 0.9),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// − qty + in a rounded pill. A null callback disables that side.
class QtyPill extends StatelessWidget {
  const QtyPill({
    Key? key,
    required this.qty,
    required this.onMinus,
    required this.onPlus,
    this.compact = false,
  }) : super(key: key);

  final int qty;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 44.0;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ShopColors.canvas,
        borderRadius: BorderRadius.circular(size),
        border: Border.all(color: ShopColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove_rounded, onMinus, size),
          SizedBox(
            width: compact ? 28 : 36,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '$qty',
                key: ValueKey(qty),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w800,
                  color: ShopColors.ink,
                ),
              ),
            ),
          ),
          _btn(Icons.add_rounded, onPlus, size),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap, double size) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? Colors.white : Colors.transparent,
      shape: const CircleBorder(),
      elevation: enabled ? 1 : 0,
      shadowColor: ShopColors.ink.withValues(alpha: 0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        child: SizedBox(
          width: size - 8,
          height: size - 8,
          child: Icon(icon,
              size: size * 0.45,
              color: enabled ? ShopColors.ink : ShopColors.inkSoft.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}

/// "Sold out" / "Only 3 left" pill, or nothing when stock isn't worth
/// mentioning. [left] null means unlimited.
class StockBadge extends StatelessWidget {
  const StockBadge({Key? key, required this.left, this.soldOut = false})
      : super(key: key);

  final int? left;
  final bool soldOut;

  static bool shows(int? left, bool soldOut) =>
      soldOut || (left != null && left <= 5);

  @override
  Widget build(BuildContext context) {
    if (!shows(left, soldOut)) return const SizedBox.shrink();
    final gone = soldOut || left == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: gone ? ShopColors.ink : ShopColors.warning,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        gone ? 'Sold out' : 'Only $left left',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Fades and rises into place, staggered by [index] — the grid assembles
/// itself instead of popping in all at once.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({Key? key, required this.child, this.index = 0})
      : super(key: key);

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    final delay = (index.clamp(0, 8)) * 60;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delay),
      curve: Interval(delay / (420 + delay), 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Round translucent button that reads over a photo or a gradient.
class ShopCircleButton extends StatelessWidget {
  const ShopCircleButton({
    Key? key,
    required this.icon,
    required this.onTap,
    this.light = false,
    this.tooltip,
  }) : super(key: key);

  final IconData icon;
  final VoidCallback onTap;

  /// White-on-glass for dark backgrounds; ink-on-white otherwise.
  final bool light;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: light
          ? Colors.white.withValues(alpha: 0.16)
          : Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: light ? 0 : 2,
      shadowColor: ShopColors.ink.withValues(alpha: 0.25),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon,
              size: 20, color: light ? Colors.white : ShopColors.ink),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// A floating dark toast, used instead of the default snackbar.
void showShopToast(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_rounded,
  Color iconColor = ShopColors.success,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: ShopColors.ink,
    elevation: 8,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    duration: const Duration(seconds: 3),
    content: Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
    action: actionLabel == null
        ? null
        : SnackBarAction(
            label: actionLabel,
            textColor: ShopColors.accent,
            onPressed: onAction ?? () {},
          ),
  ));
}

/// Light app bar used by the inner shop screens (cart, checkout, orders).
PreferredSizeWidget shopAppBar(
  BuildContext context, {
  required String title,
  String? subtitle,
  List<Widget> actions = const [],
  bool showBack = true,
}) {
  return AppBar(
    backgroundColor: ShopColors.canvas,
    surfaceTintColor: Colors.transparent,
    foregroundColor: ShopColors.ink,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    automaticallyImplyLeading: false,
    titleSpacing: showBack ? 4 : 20,
    leading: showBack
        ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          )
        : null,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: ShopColors.ink)),
        if (subtitle != null)
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: ShopColors.inkSoft)),
      ],
    ),
    actions: [...actions, const SizedBox(width: 8)],
  );
}

/// White rounded card with the soft shadow.
class ShopCard extends StatelessWidget {
  const ShopCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  }) : super(key: key);

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: ShopShadows.soft,
      ),
      child: child,
    );
  }
}
