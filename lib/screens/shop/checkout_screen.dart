import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../providers.dart';
import '../../providers/cart_provider.dart';
import '../../services/payments/payment_config.dart';
import '../../services/payments/payment_models.dart';
import '../../services/payments/payment_service.dart';
import 'order_status_screen.dart';
import 'pesapal_checkout_screen.dart';
import 'shop_repository.dart';

/// Collects the buyer's billing details, then drives the payment flow:
/// create the order on our backend → Pesapal's hosted page in a webview →
/// poll our backend for the real result.
///
/// The cart total shown here is indicative only. The backend re-prices the
/// order from its own catalogue, and that amount is what the buyer is charged
/// and what the confirmation screen shows.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  bool _busy = false;
  String? _error;

  /// Kept across retries so a second attempt reuses the same order id rather
  /// than orphaning the first one at the gateway.
  String? _orderId;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>();
    _firstName.text = profile.firstName;
    _lastName.text = profile.lastName;
    _email.text = profile.email;
    _phone.text = profile.phone;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final cart = context.read<CartProvider>();
    final profile = context.read<ProfileProvider>();
    final lines = cart.items
        .map((i) => OrderLine(
              productId: i.product.id,
              qty: i.qty,
              size: i.size,
              name: i.product.name,
            ))
        .toList();

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final order = await PaymentService.instance.createOrder(
        lines: lines,
        billing: BillingDetails(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
        ),
        // Recorded on the order so it shows up in "My orders" later. Both are
        // taken from the profile, not from the billing form: they are the
        // lookup key the history screen will send, and the buyer is free to
        // type a different address in the form (a colleague's, for the
        // receipt) without that hiding the order from their own history.
        attendeeId: profile.profileId,
        attendeeEmail: profile.email,
        orderId: _orderId,
      );
      _orderId = order.id;
      if (!mounted) return;

      // Nothing payable (a fully-discounted order): the gateway is never
      // called and no webhook will fire, so go straight to confirmation.
      if (order.isFree) {
        await _showResult(order.id, cancelledByBuyer: false);
        return;
      }

      final outcome = await Navigator.of(context).push<CheckoutOutcome>(
        MaterialPageRoute(
          builder: (_) => PesapalCheckoutScreen(redirectUrl: order.redirectUrl!),
        ),
      );
      if (!mounted) return;

      if (outcome == CheckoutOutcome.error) {
        setState(() {
          _busy = false;
          _error = 'The payment page could not be opened. Please try again.';
        });
        return;
      }

      // Even an abandoned or cancelled checkout gets confirmed against the
      // backend: the buyer may have paid and closed the page before the
      // redirect landed.
      await _showResult(
        order.id,
        cancelledByBuyer: outcome != CheckoutOutcome.returned,
      );
    } on PaymentException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  Future<void> _showResult(String orderId,
      {required bool cancelledByBuyer}) async {
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrderStatusScreen(
          orderId: orderId,
          cancelledByBuyer: cancelledByBuyer,
        ),
      ),
    );
    if (!mounted) return;

    if (paid == true) {
      // Only a confirmed payment empties the cart — an abandoned checkout
      // should leave it intact so the buyer can retry.
      context.read<CartProvider>().clear();
      _orderId = null;
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: kScaffoldColor,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: kConnectedBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _orderSummary(cart),
                  const SizedBox(height: 16),
                  _billingForm(),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _errorBanner(_error!),
                  ],
                ],
              ),
            ),
            _payBar(cart),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _orderSummary(CartProvider cart) {
    return _card(
      title: 'Order summary',
      child: Column(
        children: [
          for (final item in cart.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.qty} × ${item.product.name}'
                      '${item.size.isEmpty ? '' : ' (${item.size})'}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(formatPrice(item.lineTotal),
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          const Divider(height: 20),
          Row(
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(formatPrice(cart.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: kConnectedBlue)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Final total is confirmed by our payment service before you pay.',
            style: TextStyle(fontSize: 11, color: kLightNormalText),
          ),
        ],
      ),
    );
  }

  Widget _billingForm() {
    return _card(
      title: 'Billing details',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _field(_firstName, 'First name',
                      textCapitalization: TextCapitalization.words),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(_lastName, 'Last name',
                      textCapitalization: TextCapitalization.words),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(_email, 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Email is required';
                  // The gateway rejects a malformed address outright, so catch
                  // the obvious shapes before we spend a round trip on it.
                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(value);
                  return ok ? null : 'Enter a valid email';
                }),
            const SizedBox(height: 12),
            _field(_phone, 'Phone (recommended)',
                keyboardType: TextInputType.phone,
                required: false,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                ],
                helper: 'Needed if you pay by M-Pesa'),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool required = true,
    String? helper,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_busy,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        isDense: true,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: validator ??
          (v) => required && (v?.trim().isEmpty ?? true)
              ? '$label is required'
              : null,
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kLogoutRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: kLogoutRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _payBar(CartProvider cart) {
    final configured = PaymentConfig.isConfigured;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!configured)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Payments are not configured for this build — set the '
                'PAYMENTS_* values in assets/.env.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: kLightNormalText),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_busy || cart.isEmpty || !configured) ? null : _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: kConnectedBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      cart.total <= 0
                          ? 'Place order'
                          : 'Pay ${formatPrice(cart.total)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 13, color: kLightNormalText),
              const SizedBox(width: 5),
              Text('Payment is handled securely by Pesapal',
                  style: TextStyle(fontSize: 11, color: kLightNormalText)),
            ],
          ),
        ],
      ),
    );
  }
}
