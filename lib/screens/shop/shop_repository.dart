import 'package:intl/intl.dart';

/// A merchandise product. POC images are bundled assets under
/// `assets/images/shop/`; drop real product shots there with these names.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageAsset,
    required this.description,
    this.sizes = const [],
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String imageAsset;
  final String description;

  /// Empty for items without sizes (e.g. backpacks).
  final List<String> sizes;
}

final NumberFormat _money = NumberFormat('#,##0', 'en_US');

/// Formats a price as "KES 2,500".
String formatPrice(double amount) => 'KES ${_money.format(amount)}';

/// Mock catalogue.
///
/// TODO(backend): replace [products] with a call that fetches merchandise from
/// the shop backend, and wire real checkout/payment in CartScreen.
class ShopRepository {
  static const String placeholder = 'assets/images/shop/placeholder.png';

  static const List<String> categories = [
    'All',
    'T-Shirts',
    'Hoodies',
    'Backpacks',
    'Jackets',
  ];

  static List<Product> products() => const [
        Product(
          id: 'ts1',
          name: 'Event Logo Tee',
          category: 'T-Shirts',
          price: 2500,
          imageAsset: 'assets/images/shop/shirt.png',
          description:
              'Soft 100% cotton tee with the event logo on the chest. A '
              'comfortable everyday fit.',
          sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        ),
        Product(
          id: 'hd1',
          name: 'Classic Pullover Hoodie',
          category: 'Hoodies',
          price: 5500,
          imageAsset: 'assets/images/shop/hoodie.png',
          description:
              'Cosy fleece-lined pullover hoodie with an embroidered logo and '
              'kangaroo pocket.',
          sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        ),
        Product(
          id: 'bp1',
          name: 'Everyday Backpack',
          category: 'Backpacks',
          price: 4800,
          imageAsset: 'assets/images/shop/backpack.jpg',
          description:
              'Water-resistant 20L backpack with a padded 15" laptop sleeve.',
        ),
        Product(
          id: 'jk1',
          name: 'Softshell Jacket',
          category: 'Jackets',
          price: 8900,
          imageAsset: 'assets/images/shop/jacket.png',
          description:
              'Wind- and water-resistant softshell jacket with a fleece lining.',
          sizes: ['S', 'M', 'L', 'XL', 'XXL'],
        ),
      ];
}
