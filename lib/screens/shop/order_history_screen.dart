import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers.dart';
import '../../services/payments/payment_models.dart';
import '../../services/payments/payment_service.dart';
import 'order_status_screen.dart';
import 'shop_theme.dart';

/// The buyer's past shop orders, newest first.
///
/// Read straight from `shop_orders` through its own flow — the app keeps no
/// local order history, so this is also how a buyer finds an order placed on
/// another device or before a reinstall.
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<ShopOrder>? _orders;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = context.read<ProfileProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await PaymentService.instance.fetchOrders(
        attendeeId: profile.profileId ?? '',
        email: profile.email,
      );
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } on PaymentException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _orders?.length ?? 0;
    return Scaffold(
      backgroundColor: ShopColors.canvas,
      appBar: shopAppBar(
        context,
        title: 'My orders',
        subtitle: count == 0 ? null : '$count order${count == 1 ? '' : 's'}',
      ),
      body: RefreshIndicator(
        color: ShopColors.brand,
        onRefresh: _load,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading && _orders == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Shimmer.fromColors(
              baseColor: Colors.white,
              highlightColor: ShopColors.tile,
              child: Container(
                height: 132,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      return _message(
        icon: Icons.wifi_off_rounded,
        colour: ShopColors.danger,
        title: 'Could not load your orders',
        detail: _error!,
        action: 'Try again',
      );
    }
    final orders = _orders ?? const <ShopOrder>[];
    if (orders.isEmpty) {
      return _message(
        icon: Icons.receipt_long_rounded,
        colour: ShopColors.brand,
        title: 'No orders yet',
        detail: 'Anything you buy from the shop will show up here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => FadeSlideIn(
        key: ValueKey(orders[i].id),
        index: i,
        child: _orderCard(orders[i]),
      ),
    );
  }

  /// Empty and error states share a layout; both must stay scrollable so
  /// pull-to-refresh still works when there is nothing to scroll.
  Widget _message({
    required IconData icon,
    required Color colour,
    required String title,
    required String detail,
    String? action,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
      children: [
        Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colour.withValues(alpha: 0.1),
            ),
            child: Icon(icon, size: 48, color: colour),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: ShopColors.ink),
        ),
        const SizedBox(height: 8),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: ShopColors.inkSoft, height: 1.5, fontSize: 14),
        ),
        if (action != null) ...[
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 200,
              child: ShopPrimaryButton(
                label: action,
                height: 50,
                onPressed: _load,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _orderCard(ShopOrder order) {
    final money = NumberFormat('#,##0');
    final date = order.paidAt ?? order.createdAt;
    final colour = _statusColour(order.status);

    return PressableScale(
      // Opens the confirmation screen, which polls — so a still-pending order
      // can settle from here rather than staying pending forever in the list.
      onTap: () async {
        await Navigator.of(context).push<bool>(MaterialPageRoute(
          builder: (_) => OrderStatusScreen(orderId: order.id),
        ));
        if (mounted) _load();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: ShopShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status colour runs down the left edge.
              Container(width: 5, color: colour),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colour.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(_statusIcon(order.status),
                                color: colour, size: 21),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  date == null
                                      ? 'Order'
                                      : DateFormat('EEE, d MMM y')
                                          .format(date.toLocal()),
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: ShopColors.ink),
                                ),
                                if (date != null)
                                  Text(
                                    DateFormat('h:mm a').format(date.toLocal()),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: ShopColors.inkSoft),
                                  ),
                              ],
                            ),
                          ),
                          _statusChip(order.status, colour),
                        ],
                      ),
                      const SizedBox(height: 14),
                      for (final item in order.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                    color: ShopColors.line,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      color: ShopColors.inkSoft),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (order.items.isEmpty)
                        Text(
                          'Order ${order.id}',
                          style: const TextStyle(
                              fontSize: 13, color: ShopColors.inkSoft),
                        ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: ShopColors.line),
                      ),
                      Row(
                        children: [
                          Text(
                            order.amount > 0
                                ? '${order.currency} ${money.format(order.amount)}'
                                : 'Free',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: ShopColors.ink),
                          ),
                          const Spacer(),
                          if (order.confirmationCode?.isNotEmpty ?? false)
                            Flexible(
                              child: Text(
                                order.confirmationCode!,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    color: ShopColors.inkSoft,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded,
                              color: ShopColors.inkSoft),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColour(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return ShopColors.success;
      case PaymentStatus.failed:
      case PaymentStatus.reversed:
        return ShopColors.danger;
      case PaymentStatus.pending:
        return ShopColors.warning;
      case PaymentStatus.cancelled:
      case PaymentStatus.unknown:
        return ShopColors.inkSoft;
    }
  }

  IconData _statusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Icons.check_circle_rounded;
      case PaymentStatus.failed:
      case PaymentStatus.reversed:
        return Icons.error_rounded;
      case PaymentStatus.pending:
        return Icons.schedule_rounded;
      case PaymentStatus.cancelled:
      case PaymentStatus.unknown:
        return Icons.remove_circle_rounded;
    }
  }

  Widget _statusChip(PaymentStatus status, Color colour) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w800, color: colour),
      ),
    );
  }
}
