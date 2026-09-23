import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'payment_config.dart';
import 'payment_models.dart';

/// Client for the shop's payment backend.
///
/// Talks only to our own Directus Flows — never to the Pesapal gateway. The
/// backend owns pricing, the gateway API key, the webhook receiver and the
/// order records; this class just starts orders and reads their status.
class PaymentService {
  PaymentService._();

  static final PaymentService instance = PaymentService._();

  static const Uuid _uuid = Uuid();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: 15000,
    receiveTimeout: 30000,
    sendTimeout: 15000,
    contentType: Headers.jsonContentType,
    // Read the body ourselves so backend errors surface as a message rather
    // than a bare DioError.
    validateStatus: (_) => true,
  ));

  /// Creates an order on our backend, which prices it, records it and (unless
  /// it's free) asks the gateway for a Pesapal checkout URL.
  ///
  /// [lines] carry product ids and quantities only — the returned
  /// [ShopOrder.amount] is the backend's authoritative total, so show that (not
  /// the cart's local total) on any confirmation UI.
  Future<ShopOrder> createOrder({
    required List<OrderLine> lines,
    required BillingDetails billing,
    String? attendeeId,
    String? attendeeEmail,
    String? eventId,
    String? orderId,
  }) async {
    if (!PaymentConfig.isConfigured) {
      throw const PaymentException(
          'Payments are not configured for this build.');
    }
    if (lines.isEmpty) {
      throw const PaymentException('Your cart is empty.');
    }

    // Generated client-side so a retry of the same checkout reuses the id and
    // the backend can treat the second call as a no-op (the gateway docs
    // require the whole flow to be idempotent).
    final id = orderId ?? 'shop-${_uuid.v4()}';

    final payload = <String, dynamic>{
      'order_id': id,
      'currency': PaymentConfig.currency,
      'items': lines.map((l) => l.toJson()).toList(),
      'billing_address': billing.toJson(),
      'callback_url': PaymentConfig.callbackUrl,
      'cancellation_url': PaymentConfig.cancellationUrl,
      // Stored on the order so the buyer can find it again later. Together they
      // are the order-history lookup key — see
      // `tool/directus_flows/flow5_orders.js`. Both come from the signed-in
      // profile, deliberately not from [billing]: the billing address is
      // whatever the buyer typed, and an order should still appear in their own
      // history if they had the receipt sent somewhere else.
      if (attendeeId != null && attendeeId.isNotEmpty)
        'attendee_id': attendeeId,
      if (attendeeEmail != null && attendeeEmail.isNotEmpty)
        'attendee_email': attendeeEmail.trim().toLowerCase(),
      if (eventId != null && eventId.isNotEmpty) 'event_id': eventId,
    };

    final json = await _post(PaymentConfig.createOrderEndpoint, payload,
        what: 'create order');

    // An empty body means the flow died part-way. Without this the order would
    // look free (no redirect_url), and the buyer would be sent to a
    // confirmation screen for a payment that was never started.
    if (!json.containsKey('status') && !json.containsKey('redirect_url')) {
      throw const PaymentException(
          'The payment service returned an unexpected response. Please try '
          'again.');
    }

    final order = ShopOrder.fromJson({'order_id': id, ...json});
    debugPrint('[Payments] created order ${order.id} '
        'amount=${order.amount} ${order.currency} '
        'tracking=${order.orderTrackingId} free=${order.isFree}');
    return order;
  }

  /// Reads the current status of an order from our backend.
  Future<ShopOrder> fetchStatus(String orderId) async {
    final json = await _post(
      PaymentConfig.orderStatusEndpoint,
      {'order_id': orderId},
      what: 'fetch order status',
    );
    return ShopOrder.fromJson({'order_id': orderId, ...json});
  }

  /// Lists the buyer's past orders, newest first.
  ///
  /// Both [attendeeId] and [email] are required, and the backend refuses the
  /// request without both: this endpoint is public (the app has no real
  /// session), so the pair is what stands in for authentication. See the note
  /// at the top of `tool/directus_flows/flow5_orders.js`.
  Future<List<ShopOrder>> fetchOrders({
    required String attendeeId,
    required String email,
  }) async {
    if (!PaymentConfig.hasOrderHistory) {
      throw const PaymentException(
          'Order history is not available in this build.');
    }
    if (attendeeId.isEmpty || email.isEmpty) {
      throw const PaymentException('Sign in to see your orders.');
    }

    final json = await _post(
      PaymentConfig.orderHistoryEndpoint,
      {
        'attendee_id': attendeeId,
        // Lowercased on both sides so the backend's `_eq` filter matches.
        'email': email.trim().toLowerCase(),
      },
      what: 'load your orders',
    );

    final rows = json['orders'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((row) => ShopOrder.fromJson(Map<String, dynamic>.from(row)))
        .where((o) => o.id.isNotEmpty)
        .toList();
  }

  /// Polls [fetchStatus] until the order reaches a terminal state or [timeout]
  /// elapses, whichever comes first.
  ///
  /// The buyer's return from the webview is only a hint that they're done —
  /// the webhook is what actually marks the order paid, and it can land either
  /// side of the redirect. So we keep asking rather than trusting the redirect.
  /// A timeout is not a failure: the returned order is simply still pending.
  Future<ShopOrder> pollUntilSettled(
    String orderId, {
    Duration timeout = const Duration(minutes: 3),
    Duration interval = const Duration(seconds: 3),
    void Function(ShopOrder order)? onUpdate,
  }) async {
    final deadline = DateTime.now().add(timeout);
    ShopOrder? last;
    var failures = 0;

    while (DateTime.now().isBefore(deadline)) {
      try {
        final order = await fetchStatus(orderId);
        failures = 0;
        last = order;
        onUpdate?.call(order);
        if (order.status.isTerminal) return order;
      } on PaymentException catch (e) {
        // A flaky poll shouldn't abort the wait; a persistent one should.
        failures++;
        debugPrint('[Payments] poll failed ($failures) for $orderId: $e');
        if (failures >= 5) rethrow;
      }
      await Future<void>.delayed(interval);
    }

    return last ??
        ShopOrder(
          id: orderId,
          status: PaymentStatus.pending,
          amount: 0,
          currency: PaymentConfig.currency,
        );
  }

  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body, {
    required String what,
  }) async {
    Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(url, data: body);
    } on DioError catch (e) {
      throw PaymentException(
        e.type == DioErrorType.connectTimeout ||
                e.type == DioErrorType.receiveTimeout ||
                e.type == DioErrorType.sendTimeout
            ? 'The payment service took too long to respond. Please try again.'
            : 'Could not reach the payment service. Check your connection and '
                'try again.',
      );
    }

    final data = response.data;
    final status = response.statusCode ?? 0;

    if (status < 200 || status >= 300) {
      final message = data is Map && data['error'] is String
          ? data['error'] as String
          : 'The payment service could not $what (error $status).';
      throw PaymentException(message, statusCode: status);
    }
    if (data is! Map) {
      throw PaymentException(
          'Unexpected response from the payment service while trying to $what.',
          statusCode: status);
    }

    // A Directus flow that rejects still answers 200, with the error in the
    // body rather than the status line — so a 2xx is not on its own success.
    final error = data['error'];
    if (error is String && error.isNotEmpty) {
      throw PaymentException(error, statusCode: status);
    }

    return Map<String, dynamic>.from(data);
  }
}
