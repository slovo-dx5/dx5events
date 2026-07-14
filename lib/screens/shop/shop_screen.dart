import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'shop_repository.dart';

/// Merchandise shop (POC): browse products by category, open a product, add to
/// cart. Cart badge in the app bar opens the cart.
class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final all = ShopRepository.products();
    final products = _category == 'All'
        ? all
        : all.where((p) => p.category == _category).toList();

    return Scaffold(
      backgroundColor: kScaffoldColor,
      appBar: AppBar(
        title: const Text('Shop'),
        backgroundColor: kConnectedBlue,
        foregroundColor: Colors.white,
        actions: const [CartButton()],
      ),
      body: Column(
        children: [
          _categoryBar(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.66,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) => _productCard(products[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBar() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: ShopRepository.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = ShopRepository.categories[i];
          final selected = c == _category;
          return ChoiceChip(
            label: Text(c),
            selected: selected,
            onSelected: (_) => setState(() => _category = c),
            selectedColor: kConnectedBlue,
            labelStyle: TextStyle(
              color: selected ? Colors.white : kLightBoldText,
              fontWeight: FontWeight.w500,
            ),
            backgroundColor: Colors.white,
          );
        },
      ),
    );
  }

  Widget _productCard(Product p) {
    return GestureDetector(
      onTap: () => PersistentNavBarNavigator.pushNewScreen(
        context,
        screen: ProductDetailScreen(product: p),
        withNavBar: false,
        pageTransitionAnimation: PageTransitionAnimation.slideRight,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: p.id,
                child: ProductImage(assetPath: p.imageAsset),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(formatPrice(p.price),
                      style: const TextStyle(
                          color: kConnectedBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Product image with a graceful fallback while real assets aren't added yet.
class ProductImage extends StatelessWidget {
  const ProductImage({Key? key, required this.assetPath}) : super(key: key);
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Image.asset(ShopRepository.placeholder,
            width: 48, color: Colors.grey),
      ),
    );
  }
}

/// App-bar cart icon with an item-count badge.
class CartButton extends StatelessWidget {
  const CartButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().count;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () => PersistentNavBarNavigator.pushNewScreen(
            context,
            screen: const CartScreen(),
            withNavBar: false,
            pageTransitionAnimation: PageTransitionAnimation.slideRight,
          ),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration:
                  const BoxDecoration(color: kConnectedRed, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text('$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}
