import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'shop_repository.dart';
import 'shop_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);
  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _size;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    final sizes = widget.product.sizes;
    if (sizes.isNotEmpty) {
      // Open on the first size that can actually be bought.
      _size = sizes.firstWhere(
        (s) => (widget.product.unitsLeft(s) ?? 1) > 0,
        orElse: () => sizes.first,
      );
    }
  }

  /// How many more of the selected size can go in the cart: units left minus
  /// what is already there. Null when the product has no stock limit.
  int? _canAdd(CartProvider cart) {
    final size = _size ?? '';
    final left = widget.product.unitsLeft(size);
    if (left == null) return null;
    final inCart = cart.items
        .where((i) => i.product.id == widget.product.id && i.size == size)
        .fold<int>(0, (sum, i) => sum + i.qty);
    return (left - inCart).clamp(0, left);
  }

  void _selectSize(String size) {
    setState(() {
      _size = size;
      final max = _canAdd(context.read<CartProvider>());
      if (max != null && max > 0 && _qty > max) _qty = max;
      if (_qty < 1) _qty = 1;
    });
  }

  void _addToCart() {
    final cart = context.read<CartProvider>();
    final max = _canAdd(cart);
    final qty = max == null || _qty <= max ? _qty : max;
    if (qty < 1) return;
    cart.add(widget.product, size: _size ?? '', qty: qty);
    setState(() => _qty = 1);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Added ${widget.product.name} to cart'),
      action: SnackBarAction(
        label: 'VIEW CART',
        onPressed: () => PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: const CartScreen(),
          withNavBar: false,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final canAdd = _canAdd(context.watch<CartProvider>());
    final left = p.unitsLeft(_size ?? '');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kConnectedBlue,
        foregroundColor: Colors.white,
        title: Text(p.category),
        actions: const [CartButton()],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Hero(tag: p.id, child: ProductImage(product: p)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(formatPrice(p.price),
                      style: const TextStyle(
                          fontSize: 18,
                          color: kConnectedBlue,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Text(p.description,
                      style: TextStyle(
                          color: kLightNormalText, height: 1.4, fontSize: 14)),
                  if (p.sizes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Size',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: p.sizes.map((s) {
                        final selected = s == _size;
                        final gone = p.unitsLeft(s) == 0;
                        return ChoiceChip(
                          label: Text(s,
                              style: gone
                                  ? const TextStyle(
                                      decoration: TextDecoration.lineThrough)
                                  : null),
                          selected: selected,
                          onSelected: gone ? null : (_) => _selectSize(s),
                          selectedColor: kConnectedBlue,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : kLightBoldText,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('Quantity',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      _qtyStepper(canAdd),
                    ],
                  ),
                  if (left != null && left > 0 && left <= 5)
                    Text('Only $left left',
                        style: const TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: canAdd == 0 ? null : _addToCart,
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(canAdd != 0
                  ? 'Add to Cart · ${formatPrice(p.price * _qty)}'
                  : left == 0
                      ? 'Sold out'
                      : 'All $left left are in your cart'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kConnectedBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _qtyStepper(int? canAdd) {
    return Row(
      children: [
        IconButton(
          onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$_qty', style: const TextStyle(fontSize: 16)),
        IconButton(
          onPressed: canAdd == null || _qty < canAdd
              ? () => setState(() => _qty++)
              : null,
          icon: Icon(Icons.add_circle_outline,
              color: canAdd == null || _qty < canAdd ? kConnectedBlue : null),
        ),
      ],
    );
  }
}
