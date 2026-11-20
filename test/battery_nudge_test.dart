import 'package:battery_plus/battery_plus.dart';
import 'package:dx5veevents/screens/shop/shop_repository.dart';
import 'package:dx5veevents/services/battery_nudge_service.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product(
  String id, {
  String category = 'Power Banks',
  double price = 300,
  Object? compareAt,
  Map<String, int>? available,
}) =>
    Product.fromJson({
      'id': id,
      'name': id,
      'category': category,
      'price': price,
      'compare_at_price': compareAt,
      if (available != null) 'available': available,
    });

void main() {
  group('Product discount', () {
    test('a compare price above price is a sale', () {
      final p = _product('a', price: 300, compareAt: 500);
      expect(p.onSale, isTrue);
      expect(p.compareAtPrice, 500);
      expect(p.savings, 200);
      expect(p.discountPercent, 40);
      expect(p.price, 300); // what is charged never changes
    });

    test('equal, lower, missing or junk compare prices are ignored', () {
      for (final raw in [300, 200, null, 'abc']) {
        final p = _product('a', price: 300, compareAt: raw);
        expect(p.onSale, isFalse, reason: '$raw');
        expect(p.compareAtPrice, isNull, reason: '$raw');
        expect(p.savings, 0, reason: '$raw');
      }
    });
  });

  group('BatteryNudgeService rules', () {
    final now = DateTime(2026, 11, 25, 12);

    bool nudge({
      int level = 20,
      BatteryState state = BatteryState.discharging,
      bool shownThisRun = false,
      DateTime? lastShown,
      DateTime? lastDeclined,
    }) =>
        BatteryNudgeService.shouldNudge(
          level: level,
          state: state,
          now: now,
          shownThisRun: shownThisRun,
          lastShown: lastShown,
          lastDeclined: lastDeclined,
        );

    test('nudges below 30% on battery', () {
      expect(nudge(level: 29), isTrue);
      expect(nudge(level: 30), isFalse);
      expect(nudge(level: 80), isFalse);
      expect(nudge(level: -1), isFalse); // no battery reported
    });

    test('never while plugged in', () {
      expect(nudge(state: BatteryState.charging), isFalse);
      expect(nudge(state: BatteryState.full), isFalse);
      expect(nudge(state: BatteryState.connectedNotCharging), isFalse);
      expect(nudge(state: BatteryState.unknown), isTrue);
    });

    test('once per run, then the cooldowns apply', () {
      expect(nudge(shownThisRun: true), isFalse);
      expect(nudge(lastShown: now.subtract(const Duration(hours: 5))), isFalse);
      expect(nudge(lastShown: now.subtract(const Duration(hours: 7))), isTrue);
      expect(nudge(lastDeclined: now.subtract(const Duration(hours: 23))),
          isFalse);
      expect(nudge(lastDeclined: now.subtract(const Duration(hours: 25))),
          isTrue);
    });

    test('suggests in-stock power banks only, cheapest first', () {
      final banks = BatteryNudgeService.powerBanksIn([
        _product('tee', category: 'T-Shirts', price: 100),
        _product('big', price: 4000),
        _product('gone', price: 50, available: {'': 0}),
        _product('small', category: ' power banks ', price: 1500),
      ]);
      expect(banks.map((p) => p.id), ['small', 'big']);
    });
  });
}
