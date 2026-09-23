import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/payments/payment_models.dart';
import '../../services/payments/payment_service.dart';
import 'shop_theme.dart';

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
      if (order.status.isPaid) HapticFeedback.heavyImpact();
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
    final paid = !_waiting && (order?.status.isPaid ?? false);

    return PopScope(
      // While polling, back would strand the buyer without an answer.
      canPop: !_waiting,
      child: Scaffold(
        backgroundColor: ShopColors.canvas,
        appBar: shopAppBar(context, title: 'Your order', showBack: !_waiting),
        body: Stack(
          children: [
            SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      children: [
                        const SizedBox(height: 12),
                        Center(child: _StatusBadge(state: _visualState())),
                        const SizedBox(height: 26),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            key: ValueKey(_title()),
                            children: [
                              Text(
                                _title(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 24,
                                    letterSpacing: -0.3,
                                    fontWeight: FontWeight.w800,
                                    color: ShopColors.ink),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _body(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: ShopColors.inkSoft,
                                    fontSize: 14.5,
                                    height: 1.55),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        if (order != null) _Ticket(order: order),
                      ],
                    ),
                  ),
                  if (!_waiting) _actions(paid),
                ],
              ),
            ),
            if (paid) const Positioned.fill(child: IgnorePointer(child: _Confetti())),
          ],
        ),
      ),
    );
  }

  _Visual _visualState() {
    if (_waiting) return _Visual.waiting;
    if (_error != null) return _Visual.error;
    switch (_order?.status ?? PaymentStatus.unknown) {
      case PaymentStatus.completed:
        return _Visual.success;
      case PaymentStatus.failed:
      case PaymentStatus.reversed:
        return _Visual.failed;
      case PaymentStatus.cancelled:
        return _Visual.cancelled;
      case PaymentStatus.pending:
      case PaymentStatus.unknown:
        return _Visual.pending;
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
        // No receipt email yet (needs SMTP on Directus), so don't promise one.
        return 'Thanks! Your payment went through and your order is '
            'confirmed. Keep the reference below for your records.';
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
                'left your account the order will be confirmed shortly.';
    }
  }

  Widget _actions(bool paid) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: ShopShadows.bar,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!paid) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _poll,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Check again',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ShopColors.ink,
                    side: const BorderSide(color: ShopColors.line, width: 1.5),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            ShopPrimaryButton(
              label: paid ? 'Done' : 'Back to cart',
              icon: paid ? Icons.check_rounded : Icons.shopping_bag_outlined,
              color: paid ? ShopColors.success : null,
              onPressed: () => Navigator.of(context).pop(paid),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Visual { waiting, success, failed, cancelled, pending, error }

/// The big round status mark. Success springs in; waiting pulses.
class _StatusBadge extends StatefulWidget {
  const _StatusBadge({required this.state});
  final _Visual state;

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (widget.state) {
      _Visual.success => (ShopColors.success, Icons.check_rounded),
      _Visual.failed => (ShopColors.danger, Icons.close_rounded),
      _Visual.error => (ShopColors.danger, Icons.wifi_off_rounded),
      _Visual.cancelled => (ShopColors.inkSoft, Icons.remove_rounded),
      _Visual.pending => (ShopColors.warning, Icons.hourglass_top_rounded),
      _Visual.waiting => (ShopColors.brand, Icons.hourglass_top_rounded),
    };
    final waiting = widget.state == _Visual.waiting;

    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding rings while we wait on the provider.
          if (waiting)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  for (final offset in const [0.0, 0.5])
                    _ring(((_pulse.value + offset) % 1.0), color),
                ],
              ),
            )
          else
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
              ),
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
              child: child,
            ),
            child: Container(
              key: ValueKey(widget.state),
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: waiting
                  ? const Padding(
                      padding: EdgeInsets.all(34),
                      child: CircularProgressIndicator(
                          strokeWidth: 3.5, color: Colors.white),
                    )
                  : Icon(icon, size: 54, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double t, Color color) {
    return Opacity(
      opacity: (1 - t).clamp(0.0, 1.0) * 0.5,
      child: Container(
        width: 104 + 66 * t,
        height: 104 + 66 * t,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}

/// The order details as a tear-off ticket.
class _Ticket extends StatelessWidget {
  const _Ticket({required this.order});
  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0');
    final rows = <(String, String)>[
      ('Order', order.id),
      if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty)
        ('Method', order.paymentMethod!),
      if (order.confirmationCode != null && order.confirmationCode!.isNotEmpty)
        ('Reference', order.confirmationCode!),
      ('Status', order.status.label),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ShopShadows.soft,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Row(
              children: [
                const Expanded(child: ShopEyebrow('Amount')),
                Text(
                  order.amount > 0
                      ? '${order.currency} ${money.format(order.amount)}'
                      : 'Free',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: ShopColors.ink),
                ),
              ],
            ),
          ),
          const _Perforation(),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
            child: Column(
              children: [
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(row.$1,
                            style: const TextStyle(
                                color: ShopColors.inkSoft, fontSize: 13.5)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onLongPress: () {
                              Clipboard.setData(ClipboardData(text: row.$2));
                              showShopToast(context, '${row.$1} copied',
                                  icon: Icons.copy_rounded,
                                  iconColor: ShopColors.brand);
                            },
                            child: Text(
                              row.$2,
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: ShopColors.ink),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed line with half-circle notches at each end, like a ticket stub.
class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    Widget notch(bool left) => Container(
          width: 12,
          height: 24,
          decoration: BoxDecoration(
            color: ShopColors.canvas,
            borderRadius: BorderRadius.horizontal(
              left: left ? Radius.zero : const Radius.circular(12),
              right: left ? const Radius.circular(12) : Radius.zero,
            ),
          ),
        );
    return Row(
      children: [
        notch(true),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final dashes = (c.maxWidth / 10).floor();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                dashes,
                (_) => Container(width: 5, height: 1.5, color: ShopColors.line),
              ),
            );
          }),
        ),
        notch(false),
      ],
    );
  }
}

/// One burst of confetti in the brand colours, played once on success.
class _Confetti extends StatefulWidget {
  const _Confetti();

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  late final List<_Piece> _pieces = () {
    final r = math.Random();
    const colors = [
      ShopColors.brand,
      ShopColors.accent,
      ShopColors.success,
      ShopColors.brandDeep,
      Color(0xFFFF6B8A),
    ];
    return List.generate(70, (_) {
      return _Piece(
        angle: -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 0.9,
        speed: 0.55 + r.nextDouble() * 0.6,
        spin: (r.nextDouble() - 0.5) * 14,
        size: 5 + r.nextDouble() * 6,
        color: colors[r.nextInt(colors.length)],
        round: r.nextBool(),
      );
    });
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        painter: _ConfettiPainter(_pieces, _c.value),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
    required this.round,
  });

  final double angle;
  final double speed;
  final double spin;
  final double size;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    // Burst from behind the status badge, then fall under gravity.
    final origin = Offset(size.width / 2, 150);
    final reach = size.height * 0.9;
    final paint = Paint();
    for (final p in pieces) {
      final v = p.speed * reach;
      final dx = math.cos(p.angle) * v * t;
      final dy = math.sin(p.angle) * v * t + 0.9 * reach * t * t;
      paint.color = p.color.withValues(alpha: (1 - t * t).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size * 0.5),
            paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
