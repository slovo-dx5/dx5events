import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../screens/shop/shop_repository.dart';
import '../screens/venue_map/venue_sites.dart' show kResortLat, kResortLng;

/// What the next few hours feel like, for picking merchandise.
enum WeatherMood { warm, cold }

/// One forecast hour.
class HourTemp {
  const HourTemp(this.time, this.celsius);
  final DateTime time;
  final double celsius;
}

/// A weather-based recommendation ready to show.
class WeatherPick {
  const WeatherPick({
    required this.mood,
    required this.celsius,
    required this.headline,
    required this.products,
  });

  final WeatherMood mood;

  /// The temperature that triggered it: the low for cold, the high for warm.
  final double celsius;

  /// e.g. "Cooling to 15°C by 9 pm" or "Up to 29°C today".
  final String headline;

  /// Matching shop products, in stock, cheapest first.
  final List<Product> products;

  /// e.g. "Stay cosy with a blanket" / "Stay cool in a tee".
  String get pitch => mood == WeatherMood.cold
      ? 'Stay warm — blankets and layers in the store'
      : 'Stay cool — tees in the store';
}

/// Recommends shop items from the weather where the attendee is: tees when
/// it's warm, blankets (and other warm layers) when it's about to get cold.
///
/// Location: the phone's last known position when location permission has
/// ALREADY been granted (e.g. via the venue map), otherwise the venue's
/// coordinates. This service never asks for permission itself.
///
/// Forecast: Open-Meteo (no API key; only coordinates are sent, rounded to
/// ~1 km). Cached for [_ttl] so the shop and home card share one request.
/// Note Open-Meteo's free tier is for non-commercial use; see [_fetchHours]
/// to swap providers.
class WeatherPickService {
  WeatherPickService._();

  static final WeatherPickService instance = WeatherPickService._();

  /// Look this far ahead when deciding.
  static const Duration lookahead = Duration(hours: 6);

  /// At or below this within [lookahead]: cold.
  static const double coldAtOrBelow = 18;

  /// At or above this within [lookahead] (and not cold): warm.
  static const double warmAtOrAbove = 26;

  static const Duration _ttl = Duration(minutes: 30);

  /// Product category/name words per mood, matched case-insensitively. The
  /// live categories aren't consistent ("tshirt" and "tshirts"), so this
  /// matches words rather than exact category names.
  static const Map<WeatherMood, List<String>> keywords = {
    WeatherMood.warm: ['t-shirt', 'tshirt', 't shirt', 'tee', 'shorts', 'cap'],
    WeatherMood.cold: [
      'blanket', 'throw', 'hoodie', 'jacket', 'fleece', 'sweater', 'sweatshirt',
    ],
  };

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: 8000,
    receiveTimeout: 8000,
    validateStatus: (_) => true,
  ));

  List<HourTemp>? _hours;
  DateTime? _fetchedAt;
  Future<List<HourTemp>?>? _inFlight;

  bool get enabled => kShopFeatureEnabled && kWeatherPickEnabled;

  /// The recommendation for [products] right now, or null when the weather is
  /// mild, nothing in stock matches, or the forecast can't be fetched.
  Future<WeatherPick?> pickFor(List<Product> products) async {
    if (!enabled) return null;
    final hours = await _forecast();
    if (hours == null) return null;
    return decide(hours, DateTime.now(), products);
  }

  Future<List<HourTemp>?> _forecast() {
    final at = _fetchedAt;
    if (_hours != null && at != null && DateTime.now().difference(at) < _ttl) {
      return Future.value(_hours);
    }
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<List<HourTemp>?> _load() async {
    try {
      final (lat, lng) = await _where();
      final hours = await _fetchHours(lat, lng);
      if (hours != null && hours.isNotEmpty) {
        _hours = hours;
        _fetchedAt = DateTime.now();
      }
      return _hours;
    } catch (e) {
      debugPrint('[WeatherPick] forecast failed: $e');
      return _hours; // a stale forecast beats none
    }
  }

  /// Last known position if location is already permitted, else the venue.
  Future<(double, double)> _where() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final p = await Geolocator.getLastKnownPosition();
        if (p != null) return (p.latitude, p.longitude);
      }
    } catch (e) {
      debugPrint('[WeatherPick] location unavailable: $e');
    }
    return (kResortLat, kResortLng);
  }

  /// Hourly temperatures for the next 12 hours, as local times.
  Future<List<HourTemp>?> _fetchHours(double lat, double lng) async {
    // Two decimals (~1 km) is plenty for weather and keeps the request vague.
    String round(double v) => v.toStringAsFixed(2);
    final res = await _dio.get<dynamic>(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': round(lat),
        'longitude': round(lng),
        'hourly': 'temperature_2m',
        'forecast_hours': 12,
        'timezone': 'auto',
      },
    );
    final data = res.data;
    if ((res.statusCode ?? 0) != 200 || data is! Map) return null;
    return parseOpenMeteo(Map<String, dynamic>.from(data));
  }

  // ── Pure rules (unit-tested in test/weather_pick_test.dart) ───────────────

  /// Open-Meteo's `hourly` block → [HourTemp]s. Times are the location's
  /// local wall-clock time (timezone=auto), parsed as such.
  static List<HourTemp> parseOpenMeteo(Map<String, dynamic> json) {
    final hourly = json['hourly'];
    if (hourly is! Map) return const [];
    final times = hourly['time'];
    final temps = hourly['temperature_2m'];
    if (times is! List || temps is! List) return const [];
    final out = <HourTemp>[];
    for (var i = 0; i < times.length && i < temps.length; i++) {
      final t = DateTime.tryParse('${times[i]}');
      final c = temps[i];
      if (t != null && c is num) out.add(HourTemp(t, c.toDouble()));
    }
    return out;
  }

  /// Cold if it drops to [coldAtOrBelow] within [lookahead]; otherwise warm
  /// if it reaches [warmAtOrAbove]; otherwise mild (null). Cold wins because
  /// "it's going to get cold" is the more useful thing to hear.
  static WeatherMood? classify(List<HourTemp> hours, DateTime now) {
    final window = _window(hours, now);
    if (window.isEmpty) return null;
    final low = window.map((h) => h.celsius).reduce((a, b) => a < b ? a : b);
    final high = window.map((h) => h.celsius).reduce((a, b) => a > b ? a : b);
    if (low <= coldAtOrBelow) return WeatherMood.cold;
    if (high >= warmAtOrAbove) return WeatherMood.warm;
    return null;
  }

  /// The full decision: mood, headline and matching in-stock products.
  static WeatherPick? decide(
      List<HourTemp> hours, DateTime now, List<Product> products) {
    final mood = classify(hours, now);
    if (mood == null) return null;
    final matching = products
        .where((p) => !p.soldOut && matches(p, mood))
        .toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    if (matching.isEmpty) return null;

    final window = _window(hours, now);
    final extreme = window.reduce((a, b) => mood == WeatherMood.cold
        ? (b.celsius < a.celsius ? b : a)
        : (b.celsius > a.celsius ? b : a));
    final deg = '${extreme.celsius.round()}°C';
    // The current hour's slot (it started before now) is "right now".
    final soon = !extreme.time.isAfter(now);
    final when = DateFormat('h a').format(extreme.time).toLowerCase();
    final headline = mood == WeatherMood.cold
        ? (soon ? "It's $deg right now" : 'Cooling to $deg by $when')
        : (soon ? "It's $deg right now" : 'Up to $deg by $when');
    return WeatherPick(
      mood: mood,
      celsius: extreme.celsius,
      headline: headline,
      products: matching,
    );
  }

  /// Whether [p] suits [mood], by category or name.
  static bool matches(Product p, WeatherMood mood) {
    final text = '${p.category} ${p.name}'.toLowerCase();
    return keywords[mood]!.any((k) => _hasWord(text, k));
  }

  /// [word] at a word start, so "tee" matches "Event Logo Tee" but not
  /// "steel"; a trailing "s" is allowed ("tees", "blankets").
  static bool _hasWord(String text, String word) =>
      RegExp('(^|[^a-z])${RegExp.escape(word)}s?(\$|[^a-z])').hasMatch(text);

  /// Hours from the start of the current hour to [lookahead] ahead.
  static List<HourTemp> _window(List<HourTemp> hours, DateTime now) {
    final from = DateTime(now.year, now.month, now.day, now.hour);
    final to = now.add(lookahead);
    return hours
        .where((h) => !h.time.isBefore(from) && !h.time.isAfter(to))
        .toList();
  }
}
