import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../services/payments/payment_config.dart';

/// A merchandise product.
///
/// The photo comes from the backend (`product_image` uploaded in Directus,
/// sent by Flow 4 as a URL). The assets under `assets/images/shop/`, looked up
/// by product id, are what shows while it loads, if it fails, or when no photo
/// has been uploaded; failing both, the placeholder.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageAsset,
    required this.description,
    this.sizes = const [],
    this.imageUrl,
    this.available,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String imageAsset;
  final String description;

  /// Empty for items without sizes (e.g. backpacks).
  final List<String> sizes;

  /// Uploaded photo, when the backend supplies one. Preferred over [imageAsset].
  final String? imageUrl;

  /// Units left per size (`''` for an unsized product), or null when there is
  /// no limit — including whenever the catalogue came from the bundled
  /// fallback. Display only: Flow 1 enforces stock at checkout regardless.
  final Map<String, int>? available;

  /// Units left in [size], or null when unlimited.
  int? unitsLeft(String size) => available == null ? null : available![size] ?? 0;

  bool get soldOut =>
      available != null && available!.values.every((units) => units <= 0);

  /// Parses a row from the catalogue flow (flow4_catalogue.js).
  factory Product.fromJson(Map<String, dynamic> json) {
    final id = '${json['id'] ?? ''}';
    final image = '${json['image'] ?? ''}';
    final remote = image.startsWith('http://') || image.startsWith('https://');
    final description = json['description'] as String? ?? '';
    return Product(
      id: id,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: _toDouble(json['price']),
      imageAsset: ShopRepository.assetFor(id),
      // Falls back to the bundled copy the same way the image does. The
      // backend is authoritative for anything that affects what the buyer is
      // charged, but an empty `description` column is a blank product page for
      // no good reason — the bundled text is better than nothing, and a
      // populated column still wins.
      description:
          description.isNotEmpty ? description : ShopRepository.copyFor(id),
      sizes: (json['sizes'] as List?)?.map((s) => '$s').toList() ?? const [],
      imageUrl: remote ? image : null,
      available: _available(json['available']),
    );
  }

  static Map<String, int>? _available(Object? raw) {
    if (raw is! Map) return null;
    return raw.map((size, units) =>
        MapEntry('$size', _toDouble(units).clamp(0, double.infinity).toInt()));
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}

/// The catalogue as the shop screen needs it: products plus the category chips.
class Catalogue {
  const Catalogue({
    required this.products,
    required this.categories,
    required this.fromBackend,
  });

  final List<Product> products;

  /// Category chip labels, "All" first.
  final List<String> categories;

  /// False when this is the bundled fallback, so the UI can say the prices
  /// might be stale rather than presenting them as current.
  final bool fromBackend;
}

final NumberFormat _money = NumberFormat('#,##0', 'en_US');

/// Formats a price as "KES 2,500", in whatever currency the shop is priced in,
/// or "Free" for a zero-priced item or order.
String formatPrice(double amount) => amount <= 0
    ? 'Free'
    : '${PaymentConfig.currency} ${_money.format(amount)}';

/// Loads the merchandise catalogue.
///
/// The backend is the source of truth for prices — Flow 1 re-prices every order
/// from `shop_products` and that total is what the buyer is charged. So a
/// hardcoded list here is not merely stale, it shows a price the buyer will not
/// pay. [load] fetches the real catalogue; the bundled list below survives only
/// as an offline fallback, and the UI flags it as such.
class ShopRepository {
  static const String placeholder = 'assets/images/shop/placeholder.png';

  /// Product shots, by product id. Ship an asset here for every id in
  /// `shop_products`, or the product falls back to the placeholder.
  static const Map<String, String> _assets = {
    'ts1': 'assets/images/shop/shirt.png',
    'hd1': 'assets/images/shop/hoodie.png',
    'bp1': 'assets/images/shop/backpack.jpg',
    'jk1': 'assets/images/shop/jacket.png',
  };

  static String assetFor(String productId) =>
      _assets[productId] ?? placeholder;

  /// The bundled description for a product id, or `''` for one this build has
  /// never heard of. Used when `shop_products.description` is empty.
  static String copyFor(String productId) {
    for (final p in _bundled) {
      if (p.id == productId) return p.description;
    }
    return '';
  }

  /// Cached so switching category chips or returning from the cart doesn't
  /// re-fetch. Null until the first successful load.
  static Catalogue? _cached;

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: 10000,
    receiveTimeout: 15000,
    contentType: Headers.jsonContentType,
    validateStatus: (_) => true,
  ));

  /// Fetches the catalogue, falling back to the bundled list on any failure.
  ///
  /// Never throws: an unreachable backend should leave the shop browsable, and
  /// checkout is guarded independently — the buyer cannot be charged a stale
  /// price, only shown one.
  static Future<Catalogue> load({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached!;
    if (!PaymentConfig.hasCatalogue) return _fallback();

    try {
      final response = await _dio.post<dynamic>(
        PaymentConfig.catalogueEndpoint,
        data: const <String, dynamic>{},
      );
      final data = response.data;
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300 || data is! Map) {
        debugPrint('[Shop] catalogue fetch failed (HTTP $status)');
        return _fallback();
      }
      // A Directus flow that rejects still answers 200 with the error in the
      // body, so a 2xx is not on its own success.
      if (data['error'] != null) {
        debugPrint('[Shop] catalogue: ${data['error']}');
        return _fallback();
      }

      final rows = data['products'];
      if (rows is! List || rows.isEmpty) return _fallback();

      final products = rows
          .whereType<Map>()
          .map((row) => Product.fromJson(Map<String, dynamic>.from(row)))
          .where((p) => p.id.isNotEmpty)
          .toList();
      if (products.isEmpty) return _fallback();

      final currency = data['currency'];
      if (currency is String && currency.isNotEmpty) {
        PaymentConfig.currency = currency;
      }

      final categories = (data['categories'] as List?)
              ?.map((c) => '$c')
              .where((c) => c.isNotEmpty)
              .toList() ??
          _derivedCategories(products);

      final catalogue = Catalogue(
        products: products,
        categories: ['All', ...categories],
        fromBackend: true,
      );
      _cached = catalogue;
      debugPrint('[Shop] catalogue loaded: ${products.length} products');
      return catalogue;
    } catch (e) {
      debugPrint('[Shop] catalogue fetch error: $e');
      return _fallback();
    }
  }

  static List<String> _derivedCategories(List<Product> products) {
    final seen = <String>{};
    for (final p in products) {
      if (p.category.isNotEmpty) seen.add(p.category);
    }
    final list = seen.toList()..sort();
    return list;
  }

  /// Bundled fallback — not cached, so the next visit tries the backend again.
  static Catalogue _fallback() => Catalogue(
        products: _bundled,
        categories: ['All', ..._derivedCategories(_bundled)],
        fromBackend: false,
      );

  /// Ids and prices here must match `shop_products`, or the buyer is shown one
  /// price and charged another whenever the backend is unreachable.
  static const List<Product> _bundled = [
    Product(
      id: 'ts1',
      name: 'Event Logo Tee',
      category: 'T-Shirts',
      price: 2500,
      imageAsset: 'assets/images/shop/shirt.png',
      description: 'Soft 100% cotton tee with the event logo on the chest. A '
          'comfortable everyday fit.',
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
    ),
    Product(
      id: 'hd1',
      name: 'Classic Pullover Hoodie',
      category: 'Hoodies',
      price: 5500,
      imageAsset: 'assets/images/shop/hoodie.png',
      description: 'Cosy fleece-lined pullover hoodie with an embroidered logo '
          'and kangaroo pocket.',
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
    ),
    Product(
      id: 'bp1',
      name: 'Everyday Backpack',
      category: 'Backpacks',
      price: 4800,
      imageAsset: 'assets/images/shop/backpack.jpg',
      description: 'Water-resistant 20L backpack with a padded 15" laptop '
          'sleeve.',
    ),
    Product(
      id: 'jk1',
      name: 'Softshell Jacket',
      category: 'Jackets',
      price: 8900,
      imageAsset: 'assets/images/shop/jacket.png',
      description: 'Wind- and water-resistant softshell jacket with a fleece '
          'lining.',
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
    ),
  ];
}
