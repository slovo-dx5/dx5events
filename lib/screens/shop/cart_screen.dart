import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../services/payments/payment_config.dart';
import 'checkout_screen.dart';
import 'shop_repository.dart';
import 'shop_screen.dart';
import 'shop_theme.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: ShopColors.canvas,
      appBar: shopAppBar(
        context,
        title: 'Your cart',
        subtitle: cart.isEmpty
            ? null
            : '${cart.count} item${cart.count == 1 ? '' : 's'}',
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, cart),
              style: TextButton.styleFrom(foregroundColor: ShopColors.danger),
              child: const Text('Clear',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: cart.isEmpty
            ? const _EmptyCart()
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: cart.items.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        if (i == cart.items.length) return const _SwipeHint();
                        final item = cart.items[i];
                        return FadeSlideIn(
                          key: ValueKey(item.key),
                          index: i,
                          child: _CartTile(item: item),
                        );
                      },
                    ),
                  ),
                  _summary(context, cart),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, CartProvider cart) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Empty your cart?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Everything in it will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: ShopColors.danger),
            child: const Text('Empty cart',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      cart.clear();
    }
  }

  Widget _summary(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: ShopShadows.bar,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('Subtotal · ${cart.count} item${cart.count == 1 ? '' : 's'}',
                formatPrice(cart.total)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: ShopColors.inkSoft),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Final amount is confirmed securely at payment.',
                    style: TextStyle(
                        fontSize: 12,
                        color: ShopColors.inkSoft.withValues(alpha: 0.9)),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: ShopColors.line),
            ),
            Row(
              children: [
                const Text('Total',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: ShopColors.ink)),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(formatPrice(cart.total),
                      key: ValueKey(cart.total),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: ShopColors.ink)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ShopPrimaryButton(
              label: 'Checkout',
              icon: Icons.lock_outline_rounded,
              trailing: '→',
              onPressed: () => _checkout(context, cart),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                color: ShopColors.inkSoft,
                fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                color: ShopColors.ink,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  Future<void> _checkout(BuildContext context, CartProvider cart) async {
    if (PaymentConfig.isConfigured) {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const CheckoutScreen()),
      );
      // CheckoutScreen clears the cart itself on a confirmed payment; on any
      // other outcome the cart is intentionally left alone so the buyer can
      // retry, and we just return to it.
      return;
    }
    await _demoCheckout(context, cart);
  }

  /// Fallback for builds without payment config, so the shop still demos.
  Future<void> _demoCheckout(BuildContext context, CartProvider cart) async {
    final total = cart.total;
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Checkout',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: ShopColors.ink)),
            const SizedBox(height: 6),
            Text('${cart.count} item(s) · ${formatPrice(total)}',
                style: const TextStyle(color: ShopColors.inkSoft)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ShopColors.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'This is a demo — no payment will be taken and no order is '
                'actually placed.',
                style: TextStyle(fontSize: 13, color: ShopColors.ink),
              ),
            ),
            const SizedBox(height: 18),
            ShopPrimaryButton(
              label: 'Place order',
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );

    if (proceed != true || !context.mounted) return;
    cart.clear();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.check_circle_rounded,
            color: ShopColors.success, size: 52),
        title: const Text('Order placed!',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Thanks for trying the shop demo. Your order was recorded (no '
            'payment was taken).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (context.mounted) Navigator.of(context).maybePop();
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    // The + button stops at the stock the catalogue last reported. Flow 1
    // still has the final say at checkout.
    final left = item.product.unitsLeft(item.size);
    final canGrow = left == null || item.qty < left;

    return Dismissible(
      key: ValueKey('dismiss-${item.key}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: ShopColors.danger,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Remove',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white),
          ],
        ),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        final product = item.product;
        final size = item.size;
        final qty = item.qty;
        cart.remove(item.key);
        showShopToast(
          context,
          'Removed ${product.name}',
          icon: Icons.delete_outline_rounded,
          iconColor: ShopColors.danger,
          actionLabel: 'UNDO',
          onAction: () => cart.add(product, size: size, qty: qty),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: ShopShadows.soft,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(gradient: ShopGradients.photo),
                child: ProductImage(product: item.product),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 88),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            height: 1.25,
                            color: ShopColors.ink)),
                    const SizedBox(height: 4),
                    if (item.size.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ShopColors.canvas,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Size ${item.size}',
                            style: const TextStyle(
                                color: ShopColors.inkSoft,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700)),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(formatPrice(item.lineTotal),
                              style: const TextStyle(
                                  color: ShopColors.brandDeep,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800)),
                        ),
                        QtyPill(
                          compact: true,
                          qty: item.qty,
                          onMinus: () => cart.setQty(item.key, item.qty - 1),
                          onPlus: canGrow
                              ? () => cart.setQty(item.key, item.qty + 1)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swipe_left_rounded,
              size: 15, color: ShopColors.inkSoft.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text('Swipe an item left to remove it',
              style: TextStyle(
                  fontSize: 12,
                  color: ShopColors.inkSoft.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ShopColors.brand.withValues(alpha: 0.08),
                  ),
                ),
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: ShopGradients.brand,
                    boxShadow: ShopShadows.lifted,
                  ),
                  child: const Icon(Icons.shopping_bag_outlined,
                      size: 46, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text('Your cart is empty',
                style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: ShopColors.ink)),
            const SizedBox(height: 8),
            const Text(
              'Find something you like in the shop and it will wait for you here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ShopColors.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: ShopPrimaryButton(
                label: 'Browse the shop',
                height: 52,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
