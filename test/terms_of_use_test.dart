import 'package:dx5veevents/screens/terms_of_use_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lists the feature sections, collapsed', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TermsOfUseScreen()));
    await tester.pumpAndSettle();

    for (final title in [
      'Contact scanner',
      'Event photo gallery',
      'Find my photos (face search)',
      'Shop',
      'Harry, the AI assistant',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text(title), findsOneWidget);
    }
    expect(find.textContaining('change of mind'), findsNothing);
  });

  testWidgets('opens on the focused section', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: TermsOfUseScreen(focus: TermsSection.shop),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('change of mind'), findsOneWidget);
    expect(find.textContaining('Scan a badge only'), findsNothing);
  });
}
