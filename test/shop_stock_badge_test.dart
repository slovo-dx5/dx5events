import 'package:dx5veevents/screens/shop/shop_repository.dart';
import 'package:dx5veevents/screens/shop/shop_theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// FOMO labels: real stock always wins, the Directus label fills in otherwise.
void main() {
  test('parses the Directus values and ignores anything else', () {
    expect(StockHype.parse('selling_fast'), StockHype.sellingFast);
    expect(StockHype.parse(' Limited '), StockHype.limited);
    expect(StockHype.parse('last_few'), StockHype.lastFew);
    expect(StockHype.parse('sold_out'), isNull);
    expect(StockHype.parse(null), isNull);
  });

  test('catalogue rows carry the badge', () {
    final p = Product.fromJson(
        {'id': 'ts1', 'name': 'Tee', 'price': 100, 'badge': 'selling_fast'});
    expect(p.hype, StockHype.sellingFast);
  });

  test('sold out beats any label', () {
    final s = StockStatus.of(left: 0, hype: StockHype.sellingFast)!;
    expect(s.text, 'Sold out');
    expect(s.gone, isTrue);
  });

  test('real low stock beats the label', () {
    expect(StockStatus.of(left: 3, hype: StockHype.limited)!.text,
        'Only 3 left');
  });

  test('label shows when stock is plentiful or unlimited', () {
    expect(StockStatus.of(left: 40, hype: StockHype.limited)!.text,
        'Limited stock');
    expect(StockStatus.of(hype: StockHype.sellingFast)!.text, 'Selling fast');
    expect(StockStatus.of(hype: StockHype.lastFew)!.text, 'Last few');
  });

  test('nothing to say without a label or low stock', () {
    expect(StockStatus.of(left: 40), isNull);
    expect(StockStatus.of(), isNull);
  });
}
