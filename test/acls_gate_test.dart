import 'package:dx5veevents/services/active_event/active_event.dart';
import 'package:dx5veevents/services/active_event/active_event_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The ACLS takeover gate: built-in ACLS (event 133) opens on 27 Nov 2026,
/// Nairobi time (UTC+3), whatever the phone's own timezone.
void main() {
  final service = ActiveEventService.instance;
  tearDown(() => ActiveEventService.clock = DateTime.now);

  void at(DateTime utc) => ActiveEventService.clock = () => utc;

  test('demo mode is off', () {
    expect(ActiveEventService.kAclsDemoMode, isFalse);
  });

  test('built-in companion is ACLS 133 with no Directus config', () {
    expect(service.companion?.id, ActiveEvent.aclsEventId);
    expect(ActiveEvent.aclsEventId, '133');
  });

  test('closed today and on the 26th, upcoming strip still visible', () {
    at(DateTime.utc(2026, 11, 6, 9));
    expect(service.isCompanionDay, isFalse);
    expect(service.isCompanionUpcomingOrLive, isTrue);
    at(DateTime.utc(2026, 11, 26, 20, 59)); // 23:59 in Nairobi
    expect(service.isCompanionDay, isFalse);
  });

  test('opens at midnight on the 27th in Nairobi', () {
    at(DateTime.utc(2026, 11, 26, 21)); // 00:00 on the 27th in Nairobi
    expect(service.isCompanionDay, isTrue);
    at(DateTime.utc(2026, 11, 27, 20, 59)); // 23:59 in Nairobi
    expect(service.isCompanionDay, isTrue);
  });

  test('closes again on the 28th', () {
    at(DateTime.utc(2026, 11, 27, 21)); // 00:00 on the 28th in Nairobi
    expect(service.isCompanionDay, isFalse);
    expect(service.isCompanionUpcomingOrLive, isFalse);
  });
}
