import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funngro_assessment/features/projects/controllers/projects_controller.dart';
import 'package:funngro_assessment/features/projects/screens/projects_screen.dart';
import 'package:funngro_assessment/services/projects_api.dart';

void main() {
  group('ProjectsScreen Widget Tests', () {
    testWidgets('Renders projects list and project cards on success', (
      WidgetTester tester,
    ) async {
      final controller = ProjectsController(
        api: ProjectsApi(
          enableRandomFailures: false,
          simulatedLatency: Duration.zero,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: ProjectsScreen(controller: controller)),
      );

      // Trigger post-frame callback and settle
      await tester.pumpAndSettle();

      // Verify App Bar
      expect(find.text('Projects'), findsOneWidget);

      // Verify search bar presence
      expect(find.byType(TextField), findsOneWidget);

      // Verify category chips
      expect(find.text('Social Media'), findsOneWidget);
      expect(find.text('Graphic Design'), findsOneWidget);

      // Verify project cards are rendered
      expect(find.text('Apply Now'), findsWidgets);
    });

    testWidgets(
      'Renders error state with Retry button on initial load failure',
      (WidgetTester tester) async {
        final controller = ProjectsController(
          api: ProjectsApi(forceFailure: true, simulatedLatency: Duration.zero),
        );

        await tester.pumpWidget(
          MaterialApp(home: ProjectsScreen(controller: controller)),
        );

        await tester.pumpAndSettle();

        // Verify error state
        expect(find.text('Failed to load projects'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      },
    );
  });
}
