import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../providers.dart';
import '../../services/payments/payment_models.dart';
import '../../services/payments/payment_service.dart';
import 'order_status_screen.dart';

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
    return Scaffold(
      backgroundColor: kScaffoldColor,
      appBar: AppBar(
        title: const Text('My orders'),
        backgroundColor: kConnectedBlue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading && _orders == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _message(
        icon: Icons.wifi_off,
        colour: kLogoutRed,
        title: 'Could not load your orders',
        detail: _error!,
        action: 'Try again',
      );
    }
    final orders = _orders ?? const <ShopOrder>[];
    if (orders.isEmpty) {
      return _message(
        icon: Icons.receipt_long_outlined,
        colour: Colors.grey.shade500,
        title: 'No orders yet',
        detail: 'Anything you buy from the shop will show up here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _orderCard(orders[i]),
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
      padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
      children: [
        Icon(icon, size: 56, color: colour),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: TextStyle(color: kLightNormalText, height: 1.4, fontSize: 13),
        ),
        if (action != null) ...[
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(onPressed: _load, child: Text(action)),
          ),
        ],
      ],
    );
  }

  Widget _orderCard(ShopOrder order) {
    final money = NumberFormat('#,##0');
    final date = order.paidAt ?? order.createdAt;

    return InkWell(
      // Opens the confirmation screen, which polls — so a still-pending order
      // can settle from here rather than staying pending forever in the list.
      onTap: () async {
        await Navigator.of(context).push<bool>(MaterialPageRoute(
          builder: (_) => OrderStatusScreen(orderId: order.id),
        ));
        if (mounted) _load();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    date == null
                        ? 'Order'
                        : DateFormat('d MMM y').format(date.toLocal()),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                _statusChip(order.status),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  item.label,
                  style: TextStyle(fontSize: 13, color: kLightNormalText),
                ),
              ),
            if (order.items.isEmpty)
              Text(
                'Order ${order.id}',
                style: TextStyle(fontSize: 13, color: kLightNormalText),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${order.currency} ${money.format(order.amount)}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kConnectedBlue),
                ),
                const Spacer(),
                if (order.confirmationCode?.isNotEmpty ?? false)
                  Flexible(
                    child: Text(
                      order.confirmationCode!,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: kLightNormalText),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(PaymentStatus status) {
    late final Color colour;
    switch (status) {
      case PaymentStatus.completed:
        colour = kSuccessGreen;
        break;
      case PaymentStatus.failed:
      case PaymentStatus.reversed:
        colour = kLogoutRed;
        break;
      case PaymentStatus.pending:
        colour = kConnectedBlue;
        break;
      case PaymentStatus.cancelled:
      case PaymentStatus.unknown:
        colour = Colors.grey.shade500;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: colour),
      ),
    );
  }
}
