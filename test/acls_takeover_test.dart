// ACLS takeover widgets: the Signal Hijack intro runs its whole timeline and
// ends on its two choices; the showdown hero swaps and only links on ACLS.
import 'package:dx5veevents/services/active_event/active_event.dart';
import 'package:dx5veevents/widgets/acls/showdown_hero.dart';
import 'package:dx5veevents/widgets/acls/signal_hijack_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Signal Hijack runs its timeline and ends on both choices', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SignalHijackOverlay(),
    ));
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(SignalHijackOverlay));
      await precacheImage(const AssetImage(ActiveEvent.aclsCardImage), ctx);
      await precacheImage(const AssetImage(ActiveEvent.bundledCardImage), ctx);
    });
    await tester.pump();
    for (var ms = 0; ms < 2800; ms += 100) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Explore ACLS'), findsOneWidget);
    expect(find.text('Continue to CIO100'), findsOneWidget);
  });

  testWidgets('Showdown hero alternates and links only on ACLS', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 400 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    var tapped = 0;
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: ShowdownHero(
          cio: Image.asset(ActiveEvent.bundledCoverImage, fit: BoxFit.cover),
          cioLabel: 'CIO100 · DAY 3',
          onAclsTap: () => tapped++,
        ),
      ),
    ));
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(ShowdownHero));
      await precacheImage(const AssetImage(ActiveEvent.aclsCoverImage), ctx);
      await precacheImage(const AssetImage(ActiveEvent.bundledCoverImage), ctx);
    });
    await tester.pump();
    expect(find.text('ACLS · TODAY'), findsOneWidget);
    await tester.tap(find.byType(ShowdownHero));
    expect(tapped, 1);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('CIO100 · DAY 3'), findsOneWidget);
    await tester.tap(find.byType(ShowdownHero));
    expect(tapped, 1, reason: 'CIO100 side is not an ACLS link');
  });
}
