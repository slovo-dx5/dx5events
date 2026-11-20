import 'package:dx5veevents/screens/shop/shop_repository.dart';
import 'package:dx5veevents/services/weather_pick_service.dart';
import 'package:flutter_test/flutter_test.dart';

Product _p(String id, String category,
        {String? name, double price = 1000, Map<String, int>? available}) =>
    Product.fromJson({
      'id': id,
      'name': name ?? id,
      'category': category,
      'price': price,
      if (available != null) 'available': available,
    });

/// Hourly temps starting at [start], one per hour.
List<HourTemp> _hours(DateTime start, List<double> temps) => [
      for (var i = 0; i < temps.length; i++)
        HourTemp(start.add(Duration(hours: i)), temps[i]),
    ];

void main() {
  final now = DateTime(2026, 11, 20, 15, 20);
  final from = DateTime(2026, 11, 20, 15);

  final shop = [
    _p('tee', 'tshirts', name: 'Event Logo Tee', price: 1100),
    _p('tee2', 'T-Shirts', price: 900),
    _p('blanket', 'Blankets', name: 'Fleece Blanket', price: 3000),
    _p('hoodie', 'hoodies', price: 1500),
    _p('bag', 'backpacks', price: 2500),
    _p('gone', 'Blankets', price: 10, available: {'': 0}),
  ];

  group('classify', () {
    test('warm when it reaches 26°C in the next 6 hours', () {
      expect(WeatherPickService.classify(_hours(from, [24, 25, 27, 26]), now),
          WeatherMood.warm);
    });

    test('cold when it drops to 18°C within 6 hours, and cold wins', () {
      expect(
          WeatherPickService.classify(
              _hours(from, [27, 24, 21, 19, 18, 16, 15]), now),
          WeatherMood.cold);
    });

    test('mild weather recommends nothing', () {
      expect(
          WeatherPickService.classify(_hours(from, [22, 23, 21, 20]), now), null);
    });

    test('cold beyond the 6-hour window does not count yet', () {
      // Diani-style: hot afternoon, cold only 9 hours out.
      final temps = <double>[29, 28, 27, 26, 25, 24, 23, 22, 21, 15];
      expect(WeatherPickService.classify(_hours(from, temps), now),
          WeatherMood.warm);
    });

    test('past hours and an empty forecast are ignored', () {
      final past = _hours(from.subtract(const Duration(hours: 5)), [10, 10]);
      expect(WeatherPickService.classify(past, now), null);
      expect(WeatherPickService.classify(const [], now), null);
    });
  });

  group('decide', () {
    test('warm picks tees only, cheapest first', () {
      final pick =
          WeatherPickService.decide(_hours(from, [28, 29, 27]), now, shop)!;
      expect(pick.mood, WeatherMood.warm);
      expect(pick.products.map((p) => p.id), ['tee2', 'tee']);
      expect(pick.headline, 'Up to 29°C by 4 pm');
    });

    test('cold picks blankets and warm layers, skipping sold out', () {
      final pick = WeatherPickService.decide(
          _hours(from, [22, 20, 19, 17, 15]), now, shop)!;
      expect(pick.mood, WeatherMood.cold);
      expect(pick.products.map((p) => p.id), ['hoodie', 'blanket']);
      expect(pick.headline, 'Cooling to 15°C by 7 pm');
    });

    test('says "right now" when the extreme is this hour', () {
      final pick =
          WeatherPickService.decide(_hours(from, [14, 16, 17]), now, shop)!;
      expect(pick.headline, "It's 14°C right now");
    });

    test('nothing matching in stock means no pick', () {
      final onlyBags = [_p('bag', 'backpacks')];
      expect(WeatherPickService.decide(_hours(from, [30]), now, onlyBags), null);
    });
  });

  test('keyword matching respects word boundaries', () {
    expect(WeatherPickService.matches(_p('a', 'Steel bottles'), WeatherMood.warm),
        isFalse);
    expect(WeatherPickService.matches(_p('b', 'Tees'), WeatherMood.warm), isTrue);
    expect(WeatherPickService.matches(_p('c', 'Throws'), WeatherMood.cold),
        isTrue);
  });

  test('parses an Open-Meteo response', () {
    final hours = WeatherPickService.parseOpenMeteo({
      'hourly': {
        'time': ['2026-11-20T08:00', '2026-11-20T09:00', 'bad'],
        'temperature_2m': [25.3, 25.9, 30],
      },
    });
    expect(hours.length, 2);
    expect(hours.first.time, DateTime(2026, 11, 20, 8));
    expect(hours.last.celsius, 25.9);
  });
}
