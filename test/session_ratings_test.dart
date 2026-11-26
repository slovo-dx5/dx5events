import 'package:dx5veevents/models/agendaModel.dart';
import 'package:dx5veevents/services/session_ratings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime(2026, 11, 27);

  Session session(String start, String title) => Session(
        startTime: start,
        endTime: '10:00:00',
        title: title,
        summary: '',
        sessionId: 1,
        sessionType: 'breakout',
      );

  test('timeOn parses agenda times and rejects junk', () {
    expect(SessionRatingService.timeOn(day, '09:05:00'), DateTime(2026, 11, 27, 9, 5));
    expect(SessionRatingService.timeOn(day, '9:5'), DateTime(2026, 11, 27, 9, 5));
    expect(SessionRatingService.timeOn(day, ''), isNull);
    expect(SessionRatingService.timeOn(day, null), isNull);
  });

  test('each breakout in a block gets its own key', () {
    final block = session('11:25:00', 'Closing Tracks');
    final a = BreakoutSession(title: 'Track A: Banking');
    final b = BreakoutSession(title: 'Track B: Health');
    final keyA = SessionRatingService.keyFor(day, block, breakout: a);
    final keyB = SessionRatingService.keyFor(day, block, breakout: b);
    expect(keyA, '2026-11-27|11:25|closing tracks|track a banking');
    expect(keyA, isNot(keyB));
    expect(SessionRatingService.keyFor(day, block), '2026-11-27|11:25|closing tracks');
  });
}
