import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers.dart';
import '../../providers/cart_provider.dart';
import '../../services/payments/payment_config.dart';
import '../../services/payments/payment_models.dart';
import '../../services/payments/payment_service.dart';
import 'order_status_screen.dart';
import 'pesapal_checkout_screen.dart';
import 'shop_repository.dart';
import 'shop_screen.dart';
import 'shop_theme.dart';

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
      backgroundColor: ShopColors.canvas,
      appBar: shopAppBar(context, title: 'Checkout'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              physics: const BouncingScrollPhysics(),
              children: [
                const _Steps(),
                const SizedBox(height: 18),
                _orderSummary(cart),
                const SizedBox(height: 14),
                _billingForm(),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  child: _error == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: _errorBanner(_error!),
                        ),
                ),
              ],
            ),
          ),
          _payBar(cart),
        ],
      ),
    );
  }

  Widget _cardTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: ShopColors.brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: ShopColors.brandDeep),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ShopColors.ink)),
      ],
    );
  }

  Widget _orderSummary(CartProvider cart) {
    return ShopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.shopping_bag_outlined, 'Order summary'),
          const SizedBox(height: 16),
          for (final item in cart.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration:
                              const BoxDecoration(gradient: ShopGradients.photo),
                          child: ProductImage(product: item.product),
                        ),
                      ),
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: ShopColors.ink,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text('${item.qty}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: ShopColors.ink)),
                        if (item.size.isNotEmpty)
                          Text('Size ${item.size}',
                              style: const TextStyle(
                                  fontSize: 12, color: ShopColors.inkSoft)),
                      ],
                    ),
                  ),
                  Text(formatPrice(item.lineTotal),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ShopColors.ink)),
                ],
              ),
            ),
          const Divider(height: 20, color: ShopColors.line),
          Row(
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ShopColors.ink)),
              const Spacer(),
              Text(formatPrice(cart.total),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: ShopColors.brandDeep)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Final total is confirmed by our payment service before you pay.',
            style: TextStyle(fontSize: 11.5, color: ShopColors.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _billingForm() {
    return ShopCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardTitle(Icons.person_outline_rounded, 'Your details'),
            const SizedBox(height: 16),
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
                icon: Icons.alternate_email_rounded,
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
                icon: Icons.phone_iphone_rounded,
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
    IconData? icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool required = true,
    String? helper,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextFormField(
      controller: controller,
      enabled: !_busy,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, color: ShopColors.ink),
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: 20, color: ShopColors.inkSoft),
        filled: true,
        fillColor: ShopColors.canvas,
        labelStyle: const TextStyle(color: ShopColors.inkSoft),
        floatingLabelStyle: const TextStyle(
            color: ShopColors.brandDeep, fontWeight: FontWeight.w700),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        disabledBorder: border(Colors.transparent),
        focusedBorder: border(ShopColors.brand, 1.6),
        errorBorder: border(ShopColors.danger),
        focusedErrorBorder: border(ShopColors.danger, 1.6),
      ),
      validator: validator ??
          (v) => required && (v?.trim().isEmpty ?? true)
              ? '$label is required'
              : null,
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ShopColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ShopColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: ShopColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: ShopColors.ink,
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _payBar(CartProvider cart) {
    final configured = PaymentConfig.isConfigured;
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
            if (!configured)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Payments are not configured for this build — set the '
                  'PAYMENTS_* values in assets/.env.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: ShopColors.inkSoft),
                ),
              ),
            ShopPrimaryButton(
              busy: _busy,
              icon: cart.total <= 0 ? Icons.check_rounded : Icons.lock_rounded,
              label: cart.total <= 0
                  ? 'Place order'
                  : 'Pay ${formatPrice(cart.total)}',
              onPressed: (cart.isEmpty || !configured) ? null : _pay,
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined,
                    size: 14, color: ShopColors.success),
                SizedBox(width: 6),
                Text('Payment is handled securely by Pesapal',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: ShopColors.inkSoft,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Cart ✓ — Details ● — Payment ○
class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _step('Cart', done: true),
          _bar(active: true),
          _step('Details', current: true),
          _bar(),
          _step('Payment'),
        ],
      ),
    );
  }

  Widget _step(String label, {bool done = false, bool current = false}) {
    final on = done || current;
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: on ? ShopGradients.brand : null,
            color: on ? null : Colors.white,
            border: on ? null : Border.all(color: ShopColors.line, width: 2),
            boxShadow: current ? ShopShadows.soft : null,
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
              : current
                  ? Center(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                      ),
                    )
                  : null,
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                color: on ? ShopColors.ink : ShopColors.inkSoft)),
      ],
    );
  }

  Widget _bar({bool active = false}) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 22, left: 6, right: 6),
        decoration: BoxDecoration(
          gradient: active ? ShopGradients.brand : null,
          color: active ? null : ShopColors.line,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
