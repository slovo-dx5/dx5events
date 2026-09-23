import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../constants.dart';
import '../../services/payments/payment_config.dart';

/// How the buyer left Pesapal's hosted checkout page.
///
/// None of these prove anything about the payment — the gateway docs are
/// explicit that the redirect is a "the buyer is probably done" hint. The
/// caller must still poll the order's status.
enum CheckoutOutcome {
  /// Pesapal redirected to our `callback_url`.
  returned,

  /// Pesapal redirected to our `cancellation_url`.
  cancelled,

  /// The buyer backed out of the webview themselves.
  abandoned,

  /// The checkout page failed to load.
  error,
}

/// Hosts Pesapal's checkout page in a webview and pops as soon as it redirects
/// to one of our own URLs.
class PesapalCheckoutScreen extends StatefulWidget {
  const PesapalCheckoutScreen({Key? key, required this.redirectUrl})
      : super(key: key);

  final String redirectUrl;

  @override
  State<PesapalCheckoutScreen> createState() => _PesapalCheckoutScreenState();
}

class _PesapalCheckoutScreenState extends State<PesapalCheckoutScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            // Catch the redirect here as well as in onNavigationRequest:
            // Pesapal can arrive at the callback via a server-side redirect
            // that never surfaces as a navigation request.
            if (!_finishFor(url) && mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            if (_finishFor(request.url)) return NavigationDecision.prevent;
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint('[Payments] checkout webview error: '
                '${error.errorCode} ${error.description}');
            // Sub-resource failures (an image, a tracker) are normal and must
            // not tear down a checkout that is otherwise fine.
            if (error.isForMainFrame == false) return;
            _finish(CheckoutOutcome.error);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  /// Pops if [url] is one of our own return URLs. Matched by prefix so the
  /// `?OrderTrackingId=…` query Pesapal appends doesn't defeat the check.
  bool _finishFor(String url) {
    if (url.startsWith(PaymentConfig.cancellationUrl)) {
      _finish(CheckoutOutcome.cancelled);
      return true;
    }
    if (url.startsWith(PaymentConfig.callbackUrl)) {
      _finish(CheckoutOutcome.returned);
      return true;
    }
    return false;
  }

  void _finish(CheckoutOutcome outcome) {
    if (_finished || !mounted) return;
    _finished = true;
    debugPrint('[Payments] checkout webview finished: $outcome');
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _finished) return;
        // Back inside the hosted checkout should move back a page, not drop
        // the buyer out of a payment they're partway through.
        if (await _controller.canGoBack()) {
          await _controller.goBack();
          return;
        }
        if (!context.mounted) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Leave checkout?'),
            content: const Text(
                'Your payment is not finished. If you leave now the order will '
                'stay unpaid.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Leave',
                    style: TextStyle(color: kLogoutRed)),
              ),
            ],
          ),
        );
        if (leave == true && mounted) _finish(CheckoutOutcome.abandoned);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Secure payment'),
          backgroundColor: kConnectedBlue,
          foregroundColor: Colors.white,
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const LinearProgressIndicator(minHeight: 3),
          ],
        ),
      ),
    );
  }
}
