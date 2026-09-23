import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Runtime configuration for the shop's payment flow.
///
/// The app never talks to the Pesapal gateway
/// (`https://paymentapi.cioafrica.co`) directly — that service is
/// server-to-server only and its `x-api-key` must not ship in a mobile binary
/// (see `assets/payment_api_ref/INTEGRATION.pdf`). Instead the app calls two
/// Directus Flow webhooks on our own backend, which hold the key and are the
/// system of record for orders. See `docs/features/shop-payments-backend.md`.
///
/// Values resolve in this order (first non-empty wins):
///   1. `assets/.env` (loaded at startup via [load])
///   2. `--dart-define` compile-time values
class PaymentConfig {
  PaymentConfig._();

  /// Directus instance hosting the payment Flows.
  static String directusUrl = const String.fromEnvironment(
    'PAYMENTS_DIRECTUS_URL',
    defaultValue: 'https://subscriptions.cioafrica.co',
  );

  /// Flow id of the "create shop order" webhook. The app POSTs the cart to
  /// `{directusUrl}/flows/trigger/{createOrderFlowId}`.
  static String createOrderFlowId =
      const String.fromEnvironment('PAYMENTS_CREATE_ORDER_FLOW_ID');

  /// Flow id of the "order status" webhook, polled after checkout.
  static String orderStatusFlowId =
      const String.fromEnvironment('PAYMENTS_ORDER_STATUS_FLOW_ID');

  /// Flow id of the "catalogue" webhook. Optional: when empty the shop falls
  /// back to the bundled product list. Prices still come from the backend at
  /// checkout either way — this only affects what the buyer is *shown*.
  static String catalogueFlowId =
      const String.fromEnvironment('PAYMENTS_CATALOGUE_FLOW_ID');

  /// Flow id of the "my orders" webhook. Optional: when empty the order-history
  /// entry point is hidden rather than shown leading to an error.
  static String orderHistoryFlowId =
      const String.fromEnvironment('PAYMENTS_ORDER_HISTORY_FLOW_ID');

  /// Where the backend points Pesapal's `callback_url` / `cancellation_url`.
  /// The checkout webview watches for these to know the buyer is done — they
  /// are matched by prefix, so a trailing query string is fine.
  static String callbackUrl = const String.fromEnvironment(
    'PAYMENTS_CALLBACK_URL',
    defaultValue: 'https://subscriptions.cioafrica.co/shop/checkout/complete',
  );

  static String cancellationUrl = const String.fromEnvironment(
    'PAYMENTS_CANCEL_URL',
    defaultValue: 'https://subscriptions.cioafrica.co/shop/checkout/cancelled',
  );

  /// Currency the shop prices in. The gateway takes KES in whole shillings.
  static String currency = const String.fromEnvironment(
    'PAYMENTS_CURRENCY',
    defaultValue: 'KES',
  );

  /// Whether the app has enough config to place a real order. When false the
  /// cart falls back to the demo checkout so the shop still demos.
  static bool get isConfigured =>
      directusUrl.isNotEmpty &&
      createOrderFlowId.isNotEmpty &&
      orderStatusFlowId.isNotEmpty;

  static String get createOrderEndpoint =>
      '$directusUrl/flows/trigger/$createOrderFlowId';

  static String get orderStatusEndpoint =>
      '$directusUrl/flows/trigger/$orderStatusFlowId';

  /// Whether the remote catalogue can be fetched. Independent of
  /// [isConfigured]: the shop is browsable with the bundled list even when
  /// payments are switched off.
  static bool get hasCatalogue =>
      directusUrl.isNotEmpty && catalogueFlowId.isNotEmpty;

  static String get catalogueEndpoint =>
      '$directusUrl/flows/trigger/$catalogueFlowId';

  /// Order history needs a working payment backend *and* its own flow — there
  /// is nothing to list on a build that cannot place orders.
  static bool get hasOrderHistory =>
      isConfigured && orderHistoryFlowId.isNotEmpty;

  static String get orderHistoryEndpoint =>
      '$directusUrl/flows/trigger/$orderHistoryFlowId';

  static bool _loaded = false;

  /// Loads values from `assets/.env` if present. Safe to call once at startup;
  /// a missing file or parse error is ignored (falls back to dart-define).
  static Future<void> load([String assetPath = 'assets/.env']) async {
    if (_loaded) return;
    _loaded = true;
    try {
      final content = await rootBundle.loadString(assetPath);
      for (final line in const LineSplitter().convert(content)) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final eq = trimmed.indexOf('=');
        if (eq <= 0) continue;
        final key = trimmed.substring(0, eq).trim();
        var value = trimmed.substring(eq + 1).trim();
        if (value.length >= 2 &&
            ((value.startsWith('"') && value.endsWith('"')) ||
                (value.startsWith("'") && value.endsWith("'")))) {
          value = value.substring(1, value.length - 1);
        }
        if (value.isEmpty) continue;
        switch (key) {
          case 'PAYMENTS_DIRECTUS_URL':
            directusUrl = value;
            break;
          case 'PAYMENTS_CREATE_ORDER_FLOW_ID':
            createOrderFlowId = value;
            break;
          case 'PAYMENTS_ORDER_STATUS_FLOW_ID':
            orderStatusFlowId = value;
            break;
          case 'PAYMENTS_CATALOGUE_FLOW_ID':
            catalogueFlowId = value;
            break;
          case 'PAYMENTS_ORDER_HISTORY_FLOW_ID':
            orderHistoryFlowId = value;
            break;
          case 'PAYMENTS_CALLBACK_URL':
            callbackUrl = value;
            break;
          case 'PAYMENTS_CANCEL_URL':
            cancellationUrl = value;
            break;
          case 'PAYMENTS_CURRENCY':
            currency = value;
            break;
        }
      }
    } catch (_) {
      // No .env asset (or unreadable) — keep dart-define values.
    }
  }
}
