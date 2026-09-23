import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants.dart';
import '../../services/payments/payment_models.dart';
import '../../services/payments/payment_service.dart';

/// Confirms an order after the buyer comes back from Pesapal.
///
/// The redirect only tells us the buyer is *probably* done — the webhook to
/// our backend is the reliable signal, and it can arrive before or after the
/// redirect. So this screen polls our own backend until the order settles.
///
/// Pops `true` once the order is paid, so the caller can clear the cart.
class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({
    Key? key,
    required this.orderId,
    this.cancelledByBuyer = false,
  }) : super(key: key);

  final String orderId;

  /// Set when Pesapal sent the buyer to our cancellation URL — we still poll
  /// (a payment may have gone through anyway) but say so if it stays unpaid.
  final bool cancelledByBuyer;

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  ShopOrder? _order;
  String? _error;
  bool _waiting = true;

  @override
  void initState() {
    super.initState();
    _poll();
  }

  Future<void> _poll() async {
    setState(() {
      _waiting = true;
      _error = null;
    });
    try {
      final order = await PaymentService.instance.pollUntilSettled(
        widget.orderId,
        onUpdate: (o) {
          if (mounted) setState(() => _order = o);
        },
      );
      if (!mounted) return;
      setState(() {
        _order = order;
        _waiting = false;
      });
    } on PaymentException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _waiting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final paid = order?.status.isPaid ?? false;

    return PopScope(
      // While polling, back would strand the buyer without an answer.
      canPop: !_waiting,
      child: Scaffold(
        backgroundColor: kScaffoldColor,
        appBar: AppBar(
          title: const Text('Order'),
          backgroundColor: kConnectedBlue,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: !_waiting,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _icon(),
                const SizedBox(height: 20),
                Text(
                  _title(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  _body(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kLightNormalText, height: 1.4),
                ),
                const SizedBox(height: 20),
                _details(order),
                const Spacer(),
                if (!_waiting) ..._actions(paid),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _icon() {
    if (_waiting) {
      return const SizedBox(
        width: 56,
        height: 56,
        child: CircularProgressIndicator(strokeWidth: 4),
      );
    }
    if (_error != null) {
      return const Icon(Icons.wifi_off, size: 64, color: kLogoutRed);
    }
    switch (_order?.status ?? PaymentStatus.unknown) {
      case PaymentStatus.completed:
        return const Icon(Icons.check_circle, size: 64, color: kSuccessGreen);
      case PaymentStatus.failed:
      case PaymentStatus.reversed:
        return const Icon(Icons.error, size: 64, color: kLogoutRed);
      case PaymentStatus.cancelled:
        return Icon(Icons.cancel, size: 64, color: Colors.grey.shade500);
      case PaymentStatus.pending:
      case PaymentStatus.unknown:
        return const Icon(Icons.hourglass_bottom,
            size: 64, color: kConnectedBlue);
    }
  }

  String _title() {
    if (_waiting) return 'Confirming your payment…';
    if (_error != null) return 'Could not confirm payment';
    switch (_order?.status ?? PaymentStatus.unknown) {
      case PaymentStatus.completed:
        return (_order?.amount ?? 0) <= 0 ? 'Order confirmed' : 'Payment received';
      case PaymentStatus.failed:
        return 'Payment failed';
      case PaymentStatus.reversed:
        return 'Payment reversed';
      case PaymentStatus.cancelled:
        return 'Payment cancelled';
      case PaymentStatus.pending:
      case PaymentStatus.unknown:
        return widget.cancelledByBuyer
            ? 'Checkout cancelled'
            : 'Still processing';
    }
  }

  String _body() {
    if (_waiting) {
      return 'Hold on while we check with the payment provider. This usually '
          'takes a few seconds.';
    }
    if (_error != null) {
      return '$_error\n\nYour order is safe — if the payment went through it '
          'will still be recorded.';
    }
    switch (_order?.status ?? PaymentStatus.unknown) {
      case PaymentStatus.completed:
        if ((_order?.amount ?? 0) <= 0) {
          return 'Thanks! Your order is confirmed — there was nothing to pay.';
        }
        return 'Thanks! Your order is confirmed and a receipt has been sent to '
            'your email.';
      case PaymentStatus.failed:
        return 'The payment did not go through. Nothing has been charged — you '
            'can try again from your cart.';
      case PaymentStatus.reversed:
        return 'This payment was reversed by the provider. Please try again or '
            'contact support.';
      case PaymentStatus.cancelled:
        return 'You cancelled before paying. Your cart is still here if you '
            'want to try again.';
      case PaymentStatus.pending:
      case PaymentStatus.unknown:
        return widget.cancelledByBuyer
            ? 'You left the payment page before it completed. Your cart is '
                'still here if you want to try again.'
            : 'We have not heard back from the payment provider yet. If money '
                'left your account the order will be confirmed shortly and '
                'you will get an email.';
    }
  }

  Widget _details(ShopOrder? order) {
    if (order == null) return const SizedBox.shrink();
    final money = NumberFormat('#,##0');
    final rows = <List<String>>[
      ['Order', order.id],
      if (order.amount > 0)
        ['Amount', '${order.currency} ${money.format(order.amount)}'],
      if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty)
        ['Method', order.paymentMethod!],
      if (order.confirmationCode != null && order.confirmationCode!.isNotEmpty)
        ['Reference', order.confirmationCode!],
      ['Status', order.status.label],
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(row[0],
                      style: TextStyle(color: kLightNormalText, fontSize: 13)),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      row[1],
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _actions(bool paid) {
    return [
      if (!paid)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _poll,
            child: const Text('Check again'),
          ),
        ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(paid),
          style: ElevatedButton.styleFrom(
            backgroundColor: kConnectedBlue,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(paid ? 'Done' : 'Back to cart',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    ];
  }
}
