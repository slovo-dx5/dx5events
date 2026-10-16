import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/cart_provider.dart';
import '../../services/payments/payment_config.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'product_detail_screen.dart';
import 'shop_repository.dart';
import 'shop_theme.dart';

/// Merchandise shop: a gradient header with search, a rotating spotlight of
/// featured items, category pills that stay pinned while scrolling, and the
/// product grid. A floating cart bar appears once something is in the cart.
class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _search = TextEditingController();
  String _category = 'All';
  String _query = '';
  Catalogue? _catalogue;
  bool _loading = true;

  /// Bumped on every load so the grid replays its entrance animation.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    final catalogue = await ShopRepository.load(forceRefresh: forceRefresh);
    if (!mounted) return;
    setState(() {
      _catalogue = catalogue;
      _loading = false;
      _generation++;
      // The chip we were on may not exist in the catalogue we just loaded.
      if (!catalogue.categories.contains(_category)) _category = 'All';
    });
  }

  List<Product> get _visible {
    final all = _catalogue?.products ?? const <Product>[];
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      if (_category != 'All' && p.category != _category) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();
  }

  /// Up to three in-stock items for the carousel, uploaded photos first.
  List<Product> get _spotlight {
    final all = _catalogue?.products ?? const <Product>[];
    final candidates = all.where((p) => !p.soldOut).toList()
      ..sort((a, b) => (b.imageUrl != null ? 1 : 0) - (a.imageUrl != null ? 1 : 0));
    return candidates.take(3).toList();
  }

  void _open(Product p) {
    PersistentNavBarNavigator.pushNewScreen(
      context,
      screen: ProductDetailScreen(product: p),
      withNavBar: false,
      pageTransitionAnimation: PageTransitionAnimation.cupertino,
    );
  }

  /// One-tap add from the grid. Sized items need a size choice, so those open
  /// the product page instead.
  void _quickAdd(Product p) {
    if (p.sizes.isNotEmpty) {
      _open(p);
      return;
    }
    final cart = context.read<CartProvider>();
    final left = p.unitsLeft('');
    final inCart = cart.items
        .where((i) => i.product.id == p.id)
        .fold<int>(0, (sum, i) => sum + i.qty);
    if (left != null && inCart >= left) {
      showShopToast(context,
          left == 0 ? '${p.name} is sold out' : 'All $left left are in your cart',
          icon: Icons.info_rounded, iconColor: ShopColors.warning);
      return;
    }
    HapticFeedback.mediumImpact();
    cart.add(p);
    showShopToast(context, 'Added ${p.name}',
        actionLabel: 'VIEW CART', onAction: _openCart);
  }

  void _openCart() {
    PersistentNavBarNavigator.pushNewScreen(
      context,
      screen: const CartScreen(),
      withNavBar: false,
      pageTransitionAnimation: PageTransitionAnimation.cupertino,
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = _catalogue;
    final products = _visible;
    final browsing = _query.trim().isEmpty && _category == 'All';
    final spotlight = browsing ? _spotlight : const <Product>[];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ShopColors.canvas,
        body: Stack(
          children: [
            RefreshIndicator(
              color: ShopColors.brand,
              edgeOffset: 120,
              onRefresh: () => _load(forceRefresh: true),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _header(context)),
                  if (catalogue != null && !catalogue.fromBackend)
                    SliverToBoxAdapter(child: _offlineBanner()),
                  if (spotlight.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _Spotlight(products: spotlight, onOpen: _open),
                    ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PillsHeader(
                      categories: catalogue?.categories ?? const ['All'],
                      counts: _counts(),
                      selected: _category,
                      onSelected: (c) => setState(() => _category = c),
                    ),
                  ),
                  SliverToBoxAdapter(child: _sectionTitle(products.length)),
                  if (_loading && catalogue == null)
                    const _SkeletonGrid()
                  else if (products.isEmpty)
                    SliverToBoxAdapter(child: _emptyResults())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.64,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => FadeSlideIn(
                            key: ValueKey('${products[i].id}-$_generation'),
                            index: i,
                            child: _ProductCard(
                              product: products[i],
                              onOpen: () => _open(products[i]),
                              onQuickAdd: () => _quickAdd(products[i]),
                            ),
                          ),
                          childCount: products.length,
                        ),
                      ),
                    ),
                  // Room for the floating cart bar.
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: _CartBar(onTap: _openCart),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _counts() {
    final all = _catalogue?.products ?? const <Product>[];
    final counts = <String, int>{'All': all.length};
    for (final p in all) {
      counts[p.category] = (counts[p.category] ?? 0) + 1;
    }
    return counts;
  }

  Widget _header(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();
    return Container(
      decoration: const BoxDecoration(
        gradient: ShopGradients.hero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Soft light blooms behind the title.
          Positioned(
            right: -60,
            top: -40,
            child: _bloom(220, ShopColors.brand.withValues(alpha: 0.45)),
          ),
          Positioned(
            left: -80,
            bottom: -90,
            child: _bloom(240, Colors.white.withValues(alpha: 0.06)),
          ),
          Positioned(
            right: 36,
            bottom: 70,
            child: _bloom(70, ShopColors.accent.withValues(alpha: 0.18)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 8, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (canPop)
                      ShopCircleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        light: true,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    const Spacer(),
                    if (PaymentConfig.hasOrderHistory) ...[
                      ShopCircleButton(
                        icon: Icons.receipt_long_rounded,
                        light: true,
                        tooltip: 'My orders',
                        onTap: () => PersistentNavBarNavigator.pushNewScreen(
                          context,
                          screen: const OrderHistoryScreen(),
                          withNavBar: false,
                          pageTransitionAnimation:
                              PageTransitionAnimation.cupertino,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    const CartButton(light: true),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ShopColors.accent.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: ShopColors.accent.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 12, color: ShopColors.accent),
                          SizedBox(width: 5),
                          Text('OFFICIAL MERCH',
                              style: TextStyle(
                                  color: ShopColors.accent,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'CIO Africa Store',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Official merchandise — pay securely in the app.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13.5),
                ),
                const SizedBox(height: 20),
                _searchField(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloom(double size, Color color) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
          ),
        ),
      );

  Widget _searchField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: ShopShadows.lifted,
      ),
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        style: const TextStyle(
            fontSize: 15, color: ShopColors.ink, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search tees, hoodies, bags…',
          hintStyle: TextStyle(
              color: ShopColors.inkSoft.withValues(alpha: 0.7), fontSize: 14.5),
          prefixIcon:
              const Icon(Icons.search_rounded, color: ShopColors.inkSoft),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: ShopColors.inkSoft, size: 20),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  /// Shown when the catalogue came from the bundled list. The prices below may
  /// not be what the backend charges, and saying so is better than a silent
  /// mismatch discovered at the payment screen.
  Widget _offlineBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ShopColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ShopColors.warning.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: ShopColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing saved prices — pull down to refresh.',
              style: TextStyle(
                  fontSize: 12.5,
                  color: ShopColors.ink,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(int count) {
    final title = _query.trim().isNotEmpty
        ? 'Results'
        : _category == 'All'
            ? 'All products'
            : _category;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: ShopColors.ink)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('$count item${count == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 12.5,
                    color: ShopColors.inkSoft,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _emptyResults() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 20),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: ShopColors.brand.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 38, color: ShopColors.brand),
          ),
          const SizedBox(height: 16),
          Text(
            _query.trim().isEmpty
                ? 'Nothing here yet'
                : 'No matches for “${_query.trim()}”',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: ShopColors.ink),
          ),
          const SizedBox(height: 6),
          const Text('Try another word or browse all products.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ShopColors.inkSoft)),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () {
              _search.clear();
              setState(() {
                _query = '';
                _category = 'All';
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: ShopColors.ink,
              side: const BorderSide(color: ShopColors.line),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            child: const Text('Show everything',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Auto-advancing carousel of featured products.
class _Spotlight extends StatefulWidget {
  const _Spotlight({required this.products, required this.onOpen});
  final List<Product> products;
  final ValueChanged<Product> onOpen;

  @override
  State<_Spotlight> createState() => _SpotlightState();
}

class _SpotlightState extends State<_Spotlight> {
  final _controller = PageController(viewportFraction: 0.9);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.products.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_controller.hasClients) return;
        final next = (_page + 1) % widget.products.length;
        _controller.animateToPage(next,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          SizedBox(
            height: 176,
            child: PageView.builder(
              controller: _controller,
              itemCount: products.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _spotCard(products[i], i),
              ),
            ),
          ),
          if (products.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < products.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _page ? ShopColors.ink : ShopColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _spotCard(Product p, int i) {
    // Alternate the card tone so neighbouring slides don't blur together.
    final gradient = i.isEven
        ? ShopGradients.brand
        : const LinearGradient(
            colors: [ShopColors.ink, Color(0xFF26364D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    return PressableScale(
      onTap: () => widget.onOpen(p),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: ShopShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -30,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  flex: 11,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShopEyebrow(p.category,
                            color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(height: 6),
                        Text(
                          p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(formatPrice(p.price),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Shop',
                                      style: TextStyle(
                                          color: ShopColors.ink,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded,
                                      size: 14, color: ShopColors.ink),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        color: Colors.white,
                        child: ProductImage(product: p, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Category pills, pinned under the header while the grid scrolls.
class _PillsHeader extends SliverPersistentHeaderDelegate {
  _PillsHeader({
    required this.categories,
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final Map<String, int> counts;
  final String selected;
  final ValueChanged<String> onSelected;

  static const double _height = 64;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: ShopColors.canvas,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = categories[i];
          final on = c == selected;
          return PressableScale(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(c);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? ShopColors.ink : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: on ? ShopColors.ink : ShopColors.line),
                boxShadow: on ? ShopShadows.soft : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c,
                      style: TextStyle(
                        color: on ? Colors.white : ShopColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      )),
                  if (counts[c] != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: on
                            ? Colors.white.withValues(alpha: 0.18)
                            : ShopColors.canvas,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${counts[c]}',
                          style: TextStyle(
                            color: on ? Colors.white : ShopColors.inkSoft,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          )),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_PillsHeader old) =>
      old.selected != selected ||
      old.categories != categories ||
      old.counts.toString() != counts.toString();
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onOpen,
    required this.onQuickAdd,
  });

  final Product product;
  final VoidCallback onOpen;
  final VoidCallback onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final soldOut = p.soldOut;
    // For the badge: the most constrained size, so "Only 2 left" appears as
    // soon as any size runs low.
    final lows = (p.available?.values ?? const <int>[]).where((n) => n > 0);
    final lowest = lows.isEmpty ? null : lows.reduce((a, b) => a < b ? a : b);

    return PressableScale(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: ShopShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          decoration:
                              const BoxDecoration(gradient: ShopGradients.photo),
                          child: Hero(
                            tag: p.id,
                            child: ProductImage(product: p),
                          ),
                        ),
                      ),
                    ),
                    if (soldOut)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                              color: Colors.white.withValues(alpha: 0.55)),
                        ),
                      ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: StockBadge(left: lowest, soldOut: soldOut),
                    ),
                    if (!soldOut)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: PressableScale(
                          scale: 0.85,
                          onTap: onQuickAdd,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: ShopColors.ink,
                              shape: BoxShape.circle,
                              boxShadow: ShopShadows.lifted,
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShopEyebrow(p.category),
                  const SizedBox(height: 4),
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.25,
                      color: ShopColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        soldOut ? 'Sold out' : formatPrice(p.price),
                        style: TextStyle(
                          color: soldOut ? ShopColors.inkSoft : ShopColors.brandDeep,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (p.sizes.isNotEmpty && !soldOut) ...[
                        const Spacer(),
                        Text('${p.sizes.length} sizes',
                            style: const TextStyle(
                                color: ShopColors.inkSoft,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmering placeholder cards while the first catalogue load is in flight.
class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 14,
          childAspectRatio: 0.64,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, __) => Shimmer.fromColors(
            baseColor: Colors.white,
            highlightColor: ShopColors.tile,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          childCount: 4,
        ),
      ),
    );
  }
}

/// Floating "View cart" bar. Slides up when the cart has something in it.
class _CartBar extends StatelessWidget {
  const _CartBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final show = !cart.isEmpty;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 16),
      child: AnimatedSlide(
        offset: show ? Offset.zero : const Offset(0, 1.6),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: PressableScale(
            onTap: show ? onTap : null,
            child: Container(
              height: 64,
              padding: const EdgeInsets.fromLTRB(10, 10, 18, 10),
              decoration: BoxDecoration(
                color: ShopColors.ink,
                borderRadius: BorderRadius.circular(22),
                boxShadow: ShopShadows.lifted,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: ShopGradients.brand,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (c, a) =>
                          ScaleTransition(scale: a, child: c),
                      child: Text('${cart.count}',
                          key: ValueKey(cart.count),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('View cart',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        Text(
                          '${cart.count} item${cart.count == 1 ? '' : 's'} · ${formatPrice(cart.total)}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Product image: the photo uploaded in Directus when there is one, otherwise
/// the asset bundled for this product id, otherwise the placeholder.
///
/// The uploaded photo wins so that replacing a product shot needs no app
/// release. The bundled asset doubles as what shows while it loads and if it
/// fails, so the POC products never flash grey.
class ProductImage extends StatelessWidget {
  const ProductImage({Key? key, required this.product, this.fit = BoxFit.cover})
      : super(key: key);
  final Product product;

  /// [BoxFit.cover] fills a tile and may crop; [BoxFit.contain] shows the
  /// whole item — what the product page wants.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = product.imageUrl;
    if (url == null) return _bundled();
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, __) => _bundled(),
      errorWidget: (_, __, ___) => _bundled(),
    );
  }

  Widget _bundled() {
    if (product.imageAsset == ShopRepository.placeholder) return _placeholder();
    return Image.asset(
      product.imageAsset,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        color: ShopColors.tile,
        alignment: Alignment.center,
        child: Icon(Icons.shopping_bag_outlined,
            size: 40, color: ShopColors.inkSoft.withValues(alpha: 0.4)),
      );
}

/// Cart icon with an item-count badge that pops when the count changes.
class CartButton extends StatelessWidget {
  const CartButton({Key? key, this.light = false}) : super(key: key);

  /// For dark backgrounds (the shop header).
  final bool light;

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().count;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ShopCircleButton(
          icon: Icons.shopping_bag_outlined,
          light: light,
          tooltip: 'Cart',
          onTap: () => PersistentNavBarNavigator.pushNewScreen(
            context,
            screen: const CartScreen(),
            withNavBar: false,
            pageTransitionAnimation: PageTransitionAnimation.cupertino,
          ),
        ),
        Positioned(
          right: -2,
          top: -2,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (c, a) => ScaleTransition(
                scale: CurvedAnimation(parent: a, curve: Curves.elasticOut),
                child: c),
            child: count == 0
                ? const SizedBox.shrink(key: ValueKey(0))
                : Container(
                    key: ValueKey(count),
                    constraints:
                        const BoxConstraints(minWidth: 19, minHeight: 19),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: ShopColors.accent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: light ? ShopColors.brandDeep : Colors.white,
                          width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text('$count',
                        style: const TextStyle(
                            color: ShopColors.ink,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800)),
                  ),
          ),
        ),
      ],
    );
  }
}
