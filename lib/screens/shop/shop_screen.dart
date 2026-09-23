import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../providers/cart_provider.dart';
import '../../services/payments/payment_config.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
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
  Catalogue? _catalogue;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    final catalogue = await ShopRepository.load(forceRefresh: forceRefresh);
    if (!mounted) return;
    setState(() {
      _catalogue = catalogue;
      _loading = false;
      // The chip we were on may not exist in the catalogue we just loaded.
      if (!catalogue.categories.contains(_category)) _category = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = _catalogue;
    final all = catalogue?.products ?? const <Product>[];
    final products = _category == 'All'
        ? all
        : all.where((p) => p.category == _category).toList();

    return Scaffold(
      backgroundColor: kScaffoldColor,
      appBar: AppBar(
        title: const Text('Shop'),
        backgroundColor: kConnectedBlue,
        foregroundColor: Colors.white,
        actions: [
          if (PaymentConfig.hasOrderHistory)
            IconButton(
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: 'My orders',
              onPressed: () => PersistentNavBarNavigator.pushNewScreen(
                context,
                screen: const OrderHistoryScreen(),
                withNavBar: false,
                pageTransitionAnimation: PageTransitionAnimation.slideRight,
              ),
            ),
          const CartButton(),
        ],
      ),
      body: _loading && catalogue == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(forceRefresh: true),
              child: Column(
                children: [
                  if (catalogue != null && !catalogue.fromBackend)
                    _offlineBanner(),
                  _categoryBar(catalogue?.categories ?? const ['All']),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
            ),
    );
  }

  /// Shown when the catalogue came from the bundled list. The prices below may
  /// not be what the backend charges, and saying so is better than a silent
  /// mismatch discovered at the payment screen.
  Widget _offlineBanner() {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 16, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing saved prices — pull down to refresh.',
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBar(List<String> categories) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = categories[i];
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
                child: ProductImage(product: p),
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
                  Text(p.soldOut ? 'Sold out' : formatPrice(p.price),
                      style: TextStyle(
                          color: p.soldOut ? Colors.grey : kConnectedBlue,
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

/// Product image: the bundled asset when we have one for this product id,
/// otherwise the URL the backend supplied, otherwise the placeholder.
///
/// Bundled first because product shots ship with the app — the grid renders
/// instantly and works offline, and a backend `image` is only needed for a
/// product added after the last release.
class ProductImage extends StatelessWidget {
  const ProductImage({Key? key, required this.product}) : super(key: key);
  final Product product;

  @override
  Widget build(BuildContext context) {
    final url = product.imageUrl;
    final hasAsset = product.imageAsset != ShopRepository.placeholder;

    if (!hasAsset && url != null) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return Image.asset(
      product.imageAsset,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => url == null
          ? _placeholder()
          : Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => _placeholder(),
            ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Image.asset(ShopRepository.placeholder,
            width: 48, color: Colors.grey),
      );
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
