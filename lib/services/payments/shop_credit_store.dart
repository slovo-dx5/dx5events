import 'package:flutter/foundation.dart';

import 'payment_models.dart';
import 'payment_service.dart';

/// The signed-in buyer's leaderboard prize credit, shared by the shop home
/// banner and checkout.
///
/// Display only: the backend (Flow 1) decides what credit an order gets, so a
/// stale or missing value here can only make the on-screen total wrong, never
/// the charge.
class ShopCreditStore {
  ShopCreditStore._();
  static final ShopCreditStore instance = ShopCreditStore._();

  final ValueNotifier<ShopCredit?> credit = ValueNotifier<ShopCredit?>(null);

  String? _key;
  Future<void>? _inFlight;

  /// Loads (or reloads) the credit for this buyer. Never throws.
  Future<void> refresh({required String? attendeeId, required String email}) {
    final id = attendeeId ?? '';
    final key = '$id|${email.trim().toLowerCase()}';
    if (key != _key) credit.value = null; // a different person signed in
    _key = key;
    return _inFlight ??= PaymentService.instance
        .fetchCredit(attendeeId: id, email: email)
        .then((value) {
      if (_key == key) credit.value = value;
    }).whenComplete(() => _inFlight = null);
  }
}
