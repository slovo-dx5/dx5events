import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../helpers/analytics_helper.dart';
import '../providers/cart_provider.dart';
import '../screens/shop/cart_screen.dart';
import '../screens/shop/product_detail_screen.dart';
import '../screens/shop/shop_repository.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/shop/shop_theme.dart';
import '../services/activity_logger.dart';

/// Every place the shop is promoted outside the shop itself: the home page
/// rail, cart reminder and store card, and the bottom-nav tab. All of them
/// disappear when [kShopFeatureEnabled] is false.
///
/// Each placement logs `shop_impression` / `shop_tap` with the placement as
/// `target_id`, mirroring the sponsor reporting in `app_sponsor.dart`, so we
/// can see which placement actually sends people to the shop.
class ShopPromo {
  ShopPromo._();

  static const String railTitle = 'CIO Africa Store';

  static final Set<String> _seen = {};

  /// Records that a placement was shown, once per placement per app run.
  static void impression(String placement) {
    if (!kShopFeatureEnabled || !_seen.add(placement)) return;
    ActivityLogger.instance.log(
      action: ActivityAction.shopImpression,
      targetType: 'shop',
      targetId: placement,
    );
  }

  /// Records a tap on a placement; [productId] when it opened a product.
  static void tap(String placement, {String? productId}) {
    if (!kShopFeatureEnabled) return;
    ActivityLogger.instance.log(
      action: ActivityAction.shopTap,
      targetType: 'shop',
      targetId: placement,
      metadata: productId == null ? null : {'product_id': productId},
    );
  }

  static void openShop(BuildContext context, {required String placement}) {
    tap(placement);
    Dx5veAnalytics().logdx5veEvent(eventName: 'shop_page_opened');
    _push(context, const ShopScreen());
  }

  static void openProduct(BuildContext context, Product p,
      {required String placement}) {
    tap(placement, productId: p.id);
    _push(context, ProductDetailScreen(product: p));
  }

  static void openCart(BuildContext context, {required String placement}) {
    tap(placement);
    _push(context, const CartScreen());
  }

  static void _push(BuildContext context, Widget screen) {
    PersistentNavBarNavigator.pushNewScreen(
      context,
      screen: screen,
      withNavBar: false,
      pageTransitionAnimation: PageTransitionAnimation.cupertino,
    );
  }
}

/// Logs one [ShopPromo.impression] for [placement] when first built.
class _Seen extends StatefulWidget {
  const _Seen(this.placement, this.child);

  final String placement;
  final Widget child;

  @override
  State<_Seen> createState() => _SeenState();
}

class _SeenState extends State<_Seen> {
  @override
  void initState() {
    super.initState();
    ShopPromo.impression(widget.placement);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Home grid: the full-width store card that heads the feature grid.
class ShopHomeCard extends StatelessWidget {
  const ShopHomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kShopFeatureEnabled) return const SizedBox.shrink();
    return _Seen(
      'home_tile',
      PressableScale(
        onTap: () => ShopPromo.openShop(context, placement: 'home_tile'),
        child: Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: ShopGradients.hero,
            borderRadius: BorderRadius.circular(12),
            boxShadow: ShopShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ShopColors.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/icons/shop.png',
                  width: 24,
                  height: 24,
                  color: ShopColors.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shop',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Official event merchandise · pay in the app',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: ShopColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-nav icon for the Shop tab, with the cart count on it.
class ShopTabIcon extends StatelessWidget {
  const ShopTabIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().count;
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      backgroundColor: ShopColors.accent,
      textColor: ShopColors.ink,
      child: const Icon(Icons.storefront_rounded),
    );
  }
}
