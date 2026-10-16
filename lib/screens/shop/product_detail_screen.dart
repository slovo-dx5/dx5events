import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'shop_repository.dart';
import 'shop_screen.dart';
import 'shop_theme.dart';

/// One product: a large photo that collapses as you scroll, a content sheet
/// with stock, sizes and description, and a sticky add-to-cart bar.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);
  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _size;
  int _qty = 1;

  /// Briefly true after a successful add, so the button can say so.
  bool _justAdded = false;

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
    HapticFeedback.selectionClick();
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
    HapticFeedback.mediumImpact();
    cart.add(widget.product, size: _size ?? '', qty: qty);
    setState(() {
      _qty = 1;
      _justAdded = true;
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _justAdded = false);
    });
    showShopToast(
      context,
      'Added ${qty > 1 ? '$qty × ' : ''}${widget.product.name}',
      actionLabel: 'VIEW CART',
      onAction: () => PersistentNavBarNavigator.pushNewScreen(
        context,
        screen: const CartScreen(),
        withNavBar: false,
        pageTransitionAnimation: PageTransitionAnimation.cupertino,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final canAdd = _canAdd(context.watch<CartProvider>());
    final left = p.unitsLeft(_size ?? '');
    final width = MediaQuery.of(context).size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: width * 0.95,
              pinned: true,
              stretch: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: ShopColors.tile,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              systemOverlayStyle: SystemUiOverlayStyle.dark,
              leadingWidth: 60,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Center(
                  child: ShopCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              actions: const [
                Center(child: CartButton()),
                SizedBox(width: 12),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Container(
                  decoration: const BoxDecoration(gradient: ShopGradients.photo),
                  // The whole item, never cropped: a tall jacket or a wide
                  // bag sits in the frame instead of losing its edges.
                  padding: EdgeInsets.fromLTRB(
                      28, MediaQuery.of(context).padding.top + 56, 28, 40),
                  child: Hero(
                    tag: p.id,
                    child: ProductImage(product: p, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                // Lifts the sheet over the bottom edge of the photo.
                transform: Matrix4.translationValues(0, -24, 0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: ShopColors.brand.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ShopEyebrow(p.category,
                              color: ShopColors.brandDeep),
                        ),
                        const Spacer(),
                        _StockLine(left: left, soldOut: p.soldOut),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 25,
                            height: 1.2,
                            letterSpacing: -0.3,
                            fontWeight: FontWeight.w800,
                            color: ShopColors.ink)),
                    const SizedBox(height: 8),
                    Text(formatPrice(p.price),
                        style: const TextStyle(
                            fontSize: 22,
                            color: ShopColors.brandDeep,
                            fontWeight: FontWeight.w800)),
                    if (p.sizes.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          const Text('Select size',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: ShopColors.ink)),
                          const Spacer(),
                          if (_size != null)
                            Text('Size $_size',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: ShopColors.inkSoft,
                                    fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final s in p.sizes)
                            _SizeTile(
                              label: s,
                              selected: s == _size,
                              soldOut: p.unitsLeft(s) == 0,
                              onTap: () => _selectSize(s),
                            ),
                        ],
                      ),
                    ],
                    if (p.description.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      const Text('About this item',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: ShopColors.ink)),
                      const SizedBox(height: 8),
                      _ExpandableText(p.description),
                    ],
                    const SizedBox(height: 24),
                    const _Perks(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: ShopShadows.bar,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  QtyPill(
                    qty: _qty,
                    onMinus: _qty > 1 ? () => setState(() => _qty--) : null,
                    onPlus: canAdd == null || _qty < canAdd
                        ? () => setState(() => _qty++)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _justAdded
                          ? ShopPrimaryButton(
                              key: const ValueKey('added'),
                              label: 'Added to cart',
                              icon: Icons.check_rounded,
                              color: ShopColors.success,
                              onPressed: () {},
                            )
                          : ShopPrimaryButton(
                              key: const ValueKey('add'),
                              label: canAdd != 0
                                  ? 'Add to cart'
                                  : left == 0
                                      ? 'Sold out'
                                      : 'All in your cart',
                              icon: canAdd != 0
                                  ? Icons.shopping_bag_outlined
                                  : null,
                              trailing: canAdd != 0
                                  ? formatPrice(p.price * _qty)
                                  : null,
                              onPressed: canAdd == 0 ? null : _addToCart,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Coloured dot + "In stock" / "Only 3 left" / "Sold out".
class _StockLine extends StatelessWidget {
  const _StockLine({required this.left, required this.soldOut});
  final int? left;
  final bool soldOut;

  @override
  Widget build(BuildContext context) {
    final gone = soldOut || left == 0;
    final low = !gone && left != null && left! <= 5;
    final color = gone
        ? ShopColors.danger
        : low
            ? ShopColors.warning
            : ShopColors.success;
    final text = gone
        ? 'Sold out'
        : low
            ? 'Only $left left'
            : 'In stock';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Text(text,
            style: TextStyle(
                color: color, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _SizeTile extends StatelessWidget {
  const _SizeTile({
    required this.label,
    required this.selected,
    required this.soldOut,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool soldOut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.92,
      onTap: soldOut ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minWidth: 58),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? ShopColors.ink
              : soldOut
                  ? ShopColors.canvas
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? ShopColors.ink : ShopColors.line,
            width: 1.5,
          ),
          boxShadow: selected ? ShopShadows.soft : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: selected
                ? Colors.white
                : soldOut
                    ? ShopColors.inkSoft.withValues(alpha: 0.45)
                    : ShopColors.ink,
            decoration: soldOut ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}

/// Description clamped to four lines with a "Read more" toggle.
class _ExpandableText extends StatefulWidget {
  const _ExpandableText(this.text);
  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _open = false;

  static const _style =
      TextStyle(color: ShopColors.inkSoft, height: 1.6, fontSize: 14.5);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: _style),
        maxLines: 4,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      final overflows = painter.didExceedMaxLines;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Text(
              widget.text,
              style: _style,
              maxLines: _open ? null : 4,
              overflow: _open ? null : TextOverflow.fade,
            ),
          ),
          if (overflows)
            GestureDetector(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_open ? 'Show less' : 'Read more',
                    style: const TextStyle(
                        color: ShopColors.brandDeep,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5)),
              ),
            ),
        ],
      );
    });
  }
}

/// Reassurance row: how paying works.
class _Perks extends StatelessWidget {
  const _Perks();

  @override
  Widget build(BuildContext context) {
    const perks = [
      (Icons.lock_outline_rounded, 'Secure', 'checkout'),
      (Icons.phone_iphone_rounded, 'M-Pesa', '& cards'),
      (Icons.verified_outlined, 'Official', 'merch'),
    ];
    return Row(
      children: [
        for (var i = 0; i < perks.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: ShopColors.canvas,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Icon(perks[i].$1, color: ShopColors.brandDeep, size: 22),
                  const SizedBox(height: 6),
                  Text(perks[i].$2,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: ShopColors.ink)),
                  Text(perks[i].$3,
                      style: const TextStyle(
                          fontSize: 11.5, color: ShopColors.inkSoft)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
