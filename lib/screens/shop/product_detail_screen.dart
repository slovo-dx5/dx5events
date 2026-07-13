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
    if (widget.product.sizes.isNotEmpty) _size = widget.product.sizes.first;
  }

  void _addToCart() {
    context.read<CartProvider>().add(
          widget.product,
          size: _size ?? '',
          qty: _qty,
        );
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
              child: Hero(tag: p.id, child: ProductImage(assetPath: p.imageAsset)),
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
                        return ChoiceChip(
                          label: Text(s),
                          selected: selected,
                          onSelected: (_) => setState(() => _size = s),
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
                      _qtyStepper(),
                    ],
                  ),
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
              onPressed: _addToCart,
              icon: const Icon(Icons.add_shopping_cart),
              label: Text('Add to Cart · ${formatPrice(p.price * _qty)}'),
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

  Widget _qtyStepper() {
    return Row(
      children: [
        IconButton(
          onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$_qty', style: const TextStyle(fontSize: 16)),
        IconButton(
          onPressed: () => setState(() => _qty++),
          icon: const Icon(Icons.add_circle_outline, color: kConnectedBlue),
        ),
      ],
    );
  }
}
