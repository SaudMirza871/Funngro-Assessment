import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funngro_assessment/main.dart';

void main() {
  testWidgets('App smoke test: loads NavigationScaffold and switches tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FunngroAssessmentApp());
    await tester.pump();

    // Verify presence of navigation destinations
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Projects'), findsWidgets);
    expect(find.text('Earnings'), findsOneWidget);

    // Switch to Earnings tab
    await tester.tap(find.text('Earnings'));
    await tester.pumpAndSettle();

    expect(find.text('Earnings & Wallet'), findsOneWidget);
  });
}
