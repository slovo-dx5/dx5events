/// Where an order stands. Mirrors what the backend derives from Pesapal's
/// `payment_status_description` (see `docs/features/shop-payments-backend.md`);
/// the app only ever sees these normalized values.
enum PaymentStatus {
  /// Order created, buyer has not finished (or the webhook hasn't landed yet).
  pending,

  /// Paid — the only state that should unlock fulfilment.
  completed,

  /// Pesapal declined or the buyer's payment failed.
  failed,

  /// Buyer backed out of the hosted checkout page.
  cancelled,

  /// Reported by Pesapal for reversed/invalid transactions.
  reversed,

  /// Anything the backend sent that we don't recognise.
  unknown;

  bool get isTerminal => this != PaymentStatus.pending;

  bool get isPaid => this == PaymentStatus.completed;

  static PaymentStatus parse(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'pending':
      case 'processing':
        return PaymentStatus.pending;
      case 'completed':
      case 'paid':
      case 'success':
        return PaymentStatus.completed;
      case 'failed':
      case 'invalid':
        return PaymentStatus.failed;
      case 'cancelled':
      case 'canceled':
        return PaymentStatus.cancelled;
      case 'reversed':
        return PaymentStatus.reversed;
      default:
        return PaymentStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.reversed:
        return 'Reversed';
      case PaymentStatus.unknown:
        return 'Unknown';
    }
  }
}

/// Buyer details required by the gateway's `billing_address`. First/last name
/// and email are mandatory; phone is recommended (and required for M-Pesa).
class BillingDetails {
  const BillingDetails({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone = '',
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'email_address': email,
        if (phone.isNotEmpty) 'phone_number': phone,
      };
}

/// One line of the order as sent to the backend.
///
/// Deliberately carries no price: the backend prices the order from its own
/// catalogue, because the gateway docs are explicit that amounts must never be
/// trusted from a client.
class OrderLine {
  const OrderLine({
    required this.productId,
    required this.qty,
    this.size = '',
    this.name = '',
  });

  final String productId;
  final int qty;
  final String size;

  /// Display name, sent for the human-readable order description only.
  final String name;

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'qty': qty,
        if (size.isNotEmpty) 'size': size,
        if (name.isNotEmpty) 'name': name,
      };
}

/// One line of an order as the backend reports it back — priced from the
/// server's own catalogue, so this is what the buyer actually paid per line.
class OrderItem {
  const OrderItem({
    required this.name,
    required this.qty,
    this.size = '',
    this.lineTotal = 0,
  });

  final String name;
  final int qty;
  final String size;
  final double lineTotal;

  /// "2 × Event Logo Tee (L)"
  String get label =>
      '$qty × $name${size.isEmpty ? '' : ' ($size)'}';

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        name: json['name'] as String? ?? json['product_id'] as String? ?? 'Item',
        qty: (json['qty'] as num?)?.toInt() ?? 0,
        size: json['size'] as String? ?? '',
        lineTotal: ShopOrder._toDouble(json['line_total']),
      );
}

/// An order as the backend reports it back.
class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.status,
    required this.amount,
    required this.currency,
    this.orderTrackingId,
    this.redirectUrl,
    this.paymentMethod,
    this.confirmationCode,
    this.paidAt,
    this.createdAt,
    this.items = const [],
    this.creditApplied = 0,
  });

  /// Our own order id (`merchant_reference` at the gateway) — the id to look
  /// an order up by, since it's the one we generate.
  final String id;

  final PaymentStatus status;

  /// Authoritative total, computed by the backend.
  final double amount;
  final String currency;

  /// Pesapal's tracking id. Null for zero-amount orders.
  final String? orderTrackingId;

  /// Pesapal's hosted checkout page. Null when nothing is payable
  /// (`amount <= 0`), in which case the backend has already marked it paid.
  final String? redirectUrl;

  final String? paymentMethod;
  final String? confirmationCode;
  final DateTime? paidAt;

  /// When the order was placed. Only returned by the order-history flow — the
  /// create and status flows have no reason to send it.
  final DateTime? createdAt;

  /// The priced lines. Empty outside the order-history flow.
  final List<OrderItem> items;

  /// Leaderboard prize credit spent on this order. [amount] is what was left
  /// to pay after it.
  final double creditApplied;

  /// True when there is nothing to pay — skip the webview entirely.
  bool get isFree => amount <= 0 || (redirectUrl?.isEmpty ?? true);

  factory ShopOrder.fromJson(Map<String, dynamic> json) {
    final redirect = json['redirect_url'] as String?;
    return ShopOrder(
      id: '${json['order_id'] ?? json['id'] ?? ''}',
      status: PaymentStatus.parse(json['status'] as String?),
      amount: _toDouble(json['amount']),
      currency: json['currency'] as String? ?? 'KES',
      orderTrackingId: json['order_tracking_id'] as String?,
      redirectUrl: (redirect == null || redirect.isEmpty) ? null : redirect,
      paymentMethod: json['payment_method'] as String?,
      confirmationCode: json['confirmation_code'] as String?,
      paidAt: DateTime.tryParse('${json['paid_at'] ?? ''}'),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      items: (json['items'] as List?)
              ?.whereType<Map>()
              .map((row) => OrderItem.fromJson(Map<String, dynamic>.from(row)))
              .toList() ??
          const [],
      creditApplied: _toDouble(json['credit_applied']),
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}

/// Shop credit won on the gamification leaderboard (see
/// `functions/leaderboard_prizes.js`). The backend takes it off orders on its
/// own; the app only shows it.
class ShopCredit {
  const ShopCredit({
    required this.amount,
    required this.balance,
    this.rank,
    this.expiresAt,
  });

  /// The prize as won, in KES.
  final double amount;

  /// What is left to spend.
  final double balance;

  /// Leaderboard position (1, 2, 3).
  final int? rank;
  final DateTime? expiresAt;

  bool get hasBalance => balance > 0;

  /// What [total] comes to once the credit is taken off.
  double payable(double total) => (total - balance).clamp(0, double.infinity);

  /// The part of [total] the credit covers.
  double appliedTo(double total) => total < balance ? total : balance;

  static ShopCredit? fromJson(Object? json) {
    if (json is! Map) return null;
    final credit = ShopCredit(
      amount: ShopOrder._toDouble(json['amount']),
      balance: ShopOrder._toDouble(json['balance']),
      rank: (json['rank'] as num?)?.toInt(),
      expiresAt: DateTime.tryParse('${json['expires_at'] ?? ''}')?.toLocal(),
    );
    return credit.amount > 0 ? credit : null;
  }
}

/// Raised when the backend rejects or fails an order call. [message] is safe
/// to show to the buyer.
class PaymentException implements Exception {
  const PaymentException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'PaymentException($statusCode): $message';
}
