import 'package:flutter/foundation.dart';

import '../screens/shop/shop_repository.dart';

/// One line in the cart: a product + chosen size + quantity.
class CartItem {
  CartItem({required this.product, required this.size, this.qty = 1});

  final Product product;
  final String size;
  int qty;

  double get lineTotal => product.price * qty;

  /// Same product + size collapses into one line.
  String get key => '${product.id}|$size';
}

/// In-memory shopping cart for the shop POC. App-wide so the badge and cart
/// stay consistent across the shop, product-detail and cart screens (which are
/// pushed on the root navigator).
class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList(growable: false);

  int get count => _items.values.fold(0, (sum, i) => sum + i.qty);

  double get total => _items.values.fold(0.0, (sum, i) => sum + i.lineTotal);

  bool get isEmpty => _items.isEmpty;

  void add(Product product, {String size = '', int qty = 1}) {
    final item = CartItem(product: product, size: size, qty: qty);
    final existing = _items[item.key];
    if (existing != null) {
      existing.qty += qty;
    } else {
      _items[item.key] = item;
    }
    notifyListeners();
  }

  void setQty(String key, int qty) {
    final item = _items[key];
    if (item == null) return;
    if (qty <= 0) {
      _items.remove(key);
    } else {
      item.qty = qty;
    }
    notifyListeners();
  }

  void remove(String key) {
    _items.remove(key);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
