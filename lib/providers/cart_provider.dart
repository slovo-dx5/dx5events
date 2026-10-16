import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Shopping cart, app-wide so the badge and cart stay consistent across the
/// shop, product-detail and cart screens (which are pushed on the root
/// navigator).
///
/// Persisted to SharedPreferences as `{id, size, qty}` lines only — never the
/// product itself — so a restored cart is re-priced from the current
/// catalogue rather than showing whatever the price was when it was saved.
/// (Checkout re-prices server-side regardless; this only keeps the display
/// honest.)
class CartProvider extends ChangeNotifier {
  CartProvider() {
    _restore();
  }

  static const String _prefsKey = 'shop_cart_v1';

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
    _changed();
  }

  void setQty(String key, int qty) {
    final item = _items[key];
    if (item == null) return;
    if (qty <= 0) {
      _items.remove(key);
    } else {
      item.qty = qty;
    }
    _changed();
  }

  void remove(String key) {
    _items.remove(key);
    _changed();
  }

  void clear() {
    _items.clear();
    _changed();
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_items.isEmpty) {
        await prefs.remove(_prefsKey);
        return;
      }
      final lines = _items.values
          .map((i) => {'id': i.product.id, 'size': i.size, 'qty': i.qty})
          .toList();
      await prefs.setString(_prefsKey, jsonEncode(lines));
    } catch (e) {
      debugPrint('[Cart] save failed: $e');
    }
  }

  /// Rebuilds the saved cart against the current catalogue. Lines whose
  /// product has been withdrawn, or whose size is no longer offered, are
  /// dropped. Only touches the network when there is a saved cart, so an
  /// attendee who never opens the shop costs nothing at startup.
  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final lines = jsonDecode(raw);
      if (lines is! List || lines.isEmpty) return;

      final catalogue = await ShopRepository.load();
      final byId = {for (final p in catalogue.products) p.id: p};

      var restored = false;
      for (final line in lines.whereType<Map>()) {
        final product = byId['${line['id']}'];
        final size = '${line['size'] ?? ''}';
        final qty = line['qty'];
        if (product == null || qty is! int || qty <= 0) continue;
        if (product.sizes.isEmpty ? size.isNotEmpty : !product.sizes.contains(size)) {
          continue;
        }
        final item = CartItem(product: product, size: size, qty: qty);
        // Anything added while the catalogue was loading wins over the saved
        // line for the same product + size.
        if (_items.containsKey(item.key)) continue;
        _items[item.key] = item;
        restored = true;
      }
      if (restored) notifyListeners();
      // Rewrite so dropped lines don't linger, and so anything added during
      // the restore is merged into what's on disk.
      await _save();
    } catch (e) {
      debugPrint('[Cart] restore failed: $e');
    }
  }
}
