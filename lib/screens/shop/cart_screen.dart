import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../providers/cart_provider.dart';
import 'shop_repository.dart';
import 'shop_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: kScaffoldColor,
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: kConnectedBlue,
        foregroundColor: Colors.white,
      ),
      body: cart.isEmpty
          ? const _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _CartTile(item: cart.items[i]),
                  ),
                ),
                _summary(context, cart),
              ],
            ),
    );
  }

  Widget _summary(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              children: [
                const Text('Total',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(formatPrice(cart.total),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kConnectedBlue)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _checkout(context, cart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kConnectedBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Checkout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkout(BuildContext context, CartProvider cart) async {
    final total = cart.total;
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Checkout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('${cart.count} item(s) · ${formatPrice(total)}',
                style: TextStyle(color: kLightNormalText)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kGradientLighterBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'This is a demo — no payment will be taken and no order is '
                'actually placed.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kConnectedBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Place order'),
              ),
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
        icon: const Icon(Icons.check_circle, color: kSuccessGreen, size: 48),
        title: const Text('Order placed!'),
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 64,
              height: 64,
              child: ProductImage(assetPath: item.product.imageAsset),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (item.size.isNotEmpty)
                  Text('Size ${item.size}',
                      style: TextStyle(color: kLightNormalText, fontSize: 12)),
                const SizedBox(height: 2),
                Text(formatPrice(item.lineTotal),
                    style: const TextStyle(
                        color: kConnectedBlue, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  _stepBtn(Icons.remove, () => cart.setQty(item.key, item.qty - 1)),
                  SizedBox(
                    width: 22,
                    child: Text('${item.qty}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  _stepBtn(Icons.add, () => cart.setQty(item.key, item.qty + 1)),
                ],
              ),
              TextButton(
                onPressed: () => cart.remove(item.key),
                style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: const Text('Remove',
                    style: TextStyle(color: kLogoutRed, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: kConnectedBlue),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Your cart is empty',
              style: TextStyle(color: kLightNormalText, fontSize: 16)),
        ],
      ),
    );
  }
}
