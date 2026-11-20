import 'package:flutter/material.dart';

import '../screens/shop/shop_repository.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/shop/shop_theme.dart';
import '../services/weather_pick_service.dart';
import 'shop_promo.dart';

/// Shop-screen card: "Cooling to 15°C by 9 pm · Stay warm — blankets…" with
/// the matching products in a short horizontal row. Renders nothing when the
/// weather is mild, nothing matches, or there's no forecast.
class WeatherPickBanner extends StatefulWidget {
  const WeatherPickBanner({
    super.key,
    required this.products,
    required this.onOpen,
  });

  /// The loaded catalogue.
  final List<Product> products;
  final void Function(Product) onOpen;

  @override
  State<WeatherPickBanner> createState() => _WeatherPickBannerState();
}

class _WeatherPickBannerState extends State<WeatherPickBanner> {
  static const String _placement = 'weather_pick';
  late Future<WeatherPick?> _pick;

  @override
  void initState() {
    super.initState();
    _pick = WeatherPickService.instance.pickFor(widget.products);
  }

  @override
  void didUpdateWidget(WeatherPickBanner old) {
    super.didUpdateWidget(old);
    if (!identical(old.products, widget.products)) {
      _pick = WeatherPickService.instance.pickFor(widget.products);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherPick?>(
      future: _pick,
      builder: (context, snap) {
        final pick = snap.data;
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: pick == null ? const SizedBox(width: double.infinity) : _card(pick),
        );
      },
    );
  }

  Widget _card(WeatherPick pick) {
    ShopPromo.impression(_placement);
    final cold = pick.mood == WeatherMood.cold;
    final tint = cold ? ShopColors.brandDeep : ShopColors.warning;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 0, 12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Row(
              children: [
                Icon(cold ? Icons.ac_unit_rounded : Icons.wb_sunny_rounded,
                    size: 20, color: tint),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pick.headline,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: ShopColors.ink)),
                      Text(pick.pitch,
                          style: const TextStyle(
                              fontSize: 12, color: ShopColors.inkSoft)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 14),
              itemCount: pick.products.length.clamp(0, 6),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _tile(pick.products[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(Product p) {
    return PressableScale(
      onTap: () {
        ShopPromo.tap(_placement, productId: p.id);
        widget.onOpen(p);
      },
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ShopShadows.soft,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 52,
                height: 52,
                color: ShopColors.tile,
                child: ProductImage(product: p),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: ShopColors.ink)),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: PriceTag(
                      product: p,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: ShopColors.brandDeep),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
