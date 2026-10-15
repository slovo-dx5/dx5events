import 'package:dx5veevents/services/active_event/active_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActiveEvent labels', () {
    test('multi-day range matches the old hand-typed format', () {
      final e = ActiveEvent.fallback;
      expect(e.dateLabel, 'WED, NOV, 25TH - FRI, NOV, 27TH');
      expect(e.dayOfWeek, 'WED');
      expect(e.displayName, 'CIO100 SYMPOSIUM AND AWARDS 2026');
      expect(e.displayLocation, 'KENYA');
    });

    test('single day and ordinals', () {
      expect(ActiveEvent.dayLabel(DateTime(2026, 7, 23)), 'THU, JUL, 23RD');
      expect(ActiveEvent.dayLabel(DateTime(2026, 11, 1)), 'SUN, NOV, 1ST');
      expect(ActiveEvent.dayLabel(DateTime(2026, 11, 12)), 'THU, NOV, 12TH');
      expect(ActiveEvent.dayLabel(DateTime(2026, 11, 22)), 'SUN, NOV, 22ND');
      final oneDay = ActiveEvent(
        id: '107',
        title: 'Smart Government Summit',
        dateFrom: DateTime(2026, 7, 23, 8),
        dateTo: DateTime(2026, 7, 23, 18),
      );
      expect(oneDay.dateLabel, 'THU, JUL, 23RD');
    });
  });

  group('ActiveEvent.fromAppConfig', () {
    Map<String, dynamic> config(int id, {String? card, String? tagline}) => {
          'tagline': tagline,
          'card_image': card,
          'cover_image': null,
          'active_event': {
            'id': id,
            'title': 'Some Event',
            'date_from': '2026-11-25T08:00:00',
            'date_to': '2026-11-27T18:00:00',
            'country': 'Kenya',
            'venue': 'Diani',
            'summary': 'Event summary',
            'banner': 'banner-id',
          },
        };

    test('reads the expanded event and keeps local times', () {
      final e = ActiveEvent.fromAppConfig(config(130))!;
      expect(e.id, '130');
      expect(e.dateFrom, DateTime(2026, 11, 25, 8));
      expect(e.tagline, 'Event summary');
      expect(e.cardImageUrl, endsWith('/assets/banner-id'));
      expect(e.coverImageUrl, endsWith('/assets/banner-id'));
    });

    test('app_config overrides win over the event', () {
      final e = ActiveEvent.fromAppConfig(
          config(130, card: 'card-id', tagline: 'Custom line'))!;
      expect(e.tagline, 'Custom line');
      expect(e.cardImageUrl, endsWith('/assets/card-id'));
    });

    test('fallback event keeps its bundled art instead of the banner', () {
      final e = ActiveEvent.fromAppConfig(config(111))!;
      expect(e.cardImageUrl, isNull);
      expect(e.coverImageUrl, isNull);
    });

    test('missing event gives null', () {
      expect(ActiveEvent.fromAppConfig({'active_event': null}), isNull);
    });

    test('cache round-trips', () {
      final e = ActiveEvent.fromAppConfig(config(130, card: 'c'))!;
      expect(ActiveEvent.fromJson(e.toJson())!.toJson(), e.toJson());
    });
  });
}
