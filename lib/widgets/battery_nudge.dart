import 'package:flutter/material.dart';

import '../screens/shop/shop_screen.dart';
import '../screens/shop/shop_theme.dart';
import '../services/battery_nudge_service.dart';
import 'shop_promo.dart';

/// Wraps the main tab view and slides a soft low-battery card in above the
/// bottom nav when [BatteryNudgeService] has a suggestion. Not a dialog: it
/// never blocks what the attendee is doing, and one tap dismisses it.
class BatteryNudgeHost extends StatelessWidget {
  const BatteryNudgeHost({super.key, required this.child});

  final Widget child;

  /// Room left for the persistent bottom nav bar under the card.
  static const double _navBarHeight = 64;

  @override
  Widget build(BuildContext context) {
    final service = BatteryNudgeService.instance;
    if (!service.enabled) return child;
    final bottom = _navBarHeight + 10 + MediaQuery.of(context).padding.bottom;
    return Stack(
      children: [
        child,
        Positioned(
          left: 12,
          right: 12,
          bottom: bottom,
          child: ValueListenableBuilder<BatteryNudge?>(
            valueListenable: service.nudge,
            builder: (context, nudge, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween(begin: const Offset(0, 0.4), end: Offset.zero)
                    .animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: nudge == null
                  ? const SizedBox.shrink()
                  : _BatteryNudgeCard(key: ValueKey(nudge), nudge: nudge),
            ),
          ),
        ),
      ],
    );
  }
}

class _BatteryNudgeCard extends StatefulWidget {
  const _BatteryNudgeCard({super.key, required this.nudge});

  final BatteryNudge nudge;

  @override
  State<_BatteryNudgeCard> createState() => _BatteryNudgeCardState();
}

class _BatteryNudgeCardState extends State<_BatteryNudgeCard> {
  static const String _placement = 'battery_nudge';

  @override
  void initState() {
    super.initState();
    ShopPromo.impression(_placement);
  }

  void _view() {
    final p = widget.nudge.featured;
    BatteryNudgeService.instance.dismiss();
    ShopPromo.openProduct(context, p, placement: _placement);
  }

  void _notNow() => BatteryNudgeService.instance.dismiss(declined: true);

  @override
  Widget build(BuildContext context) {
    final p = widget.nudge.featured;
    final level = widget.nudge.level;
    return Dismissible(
      key: const ValueKey('battery_nudge'),
      direction: DismissDirection.down,
      onDismissed: (_) => _notNow(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: ShopShadows.lifted,
            border: Border.all(color: ShopColors.line),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 58,
                  height: 58,
                  color: ShopColors.tile,
                  child: ProductImage(product: p),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          level <= 15
                              ? Icons.battery_1_bar_rounded
                              : Icons.battery_3_bar_rounded,
                          size: 16,
                          color: ShopColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Battery at $level%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: ShopColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Grab a power bank so you don't miss a session.",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: ShopColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: PriceTag(
                        product: p,
                        showPercent: true,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ShopColors.brandDeep,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: _view,
                    style: FilledButton.styleFrom(
                      backgroundColor: ShopColors.brand,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('View',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  TextButton(
                    onPressed: _notNow,
                    style: TextButton.styleFrom(
                      foregroundColor: ShopColors.inkSoft,
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text('Not now',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
