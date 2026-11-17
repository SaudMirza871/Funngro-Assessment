import 'package:flutter_test/flutter_test.dart';
import 'package:funngro_assessment/services/projects_api.dart';

void main() {
  group('ProjectsApi Fake Service Tests', () {
    test(
      'Successful response returns 20 projects per page for valid pages',
      () async {
        final api = ProjectsApi(
          enableRandomFailures: false,
          simulatedLatency: Duration.zero,
        );

        final page0 = await api.getProjects(page: 0);
        expect(page0.length, equals(20));

        final page1 = await api.getProjects(page: 1);
        expect(page1.length, equals(20));

        // Verify that projects on page 0 and page 1 are distinct
        final page0Ids = page0.map((p) => p.id).toSet();
        final page1Ids = page1.map((p) => p.id).toSet();
        expect(page0Ids.intersection(page1Ids), isEmpty);

        // Verify every project has required fields: id, title, company, payout
        for (final p in page0) {
          expect(p.id, isNotEmpty);
          expect(p.title, isNotEmpty);
          expect(p.company, isNotEmpty);
          expect(p.payout, isPositive);
        }
      },
    );

    test('Empty response after page 7 (page 8 returns empty list)', () async {
      final api = ProjectsApi(
        enableRandomFailures: false,
        simulatedLatency: Duration.zero,
      );

      // Page 7 should return last batch
      final page7 = await api.getProjects(page: 7);
      expect(page7.length, equals(20));

      // Page 8 must return an empty list
      final page8 = await api.getProjects(page: 8);
      expect(page8, isEmpty);

      // Negative pages and pages beyond 8 should also return empty
      final page9 = await api.getProjects(page: 9);
      expect(page9, isEmpty);

      final pageNegative = await api.getProjects(page: -1);
      expect(pageNegative, isEmpty);
    });

    test(
      'API failure handling throws ProjectsApiException when forced or random',
      () async {
        final failingApi = ProjectsApi(
          forceFailure: true,
          simulatedLatency: Duration.zero,
        );

        expect(
          () => failingApi.getProjects(page: 0),
          throwsA(isA<ProjectsApiException>()),
        );
      },
    );

    test('Project detail lookup, apply, and bookmark functionality', () async {
      final api = ProjectsApi(
        enableRandomFailures: false,
        simulatedLatency: Duration.zero,
      );

      final projects = await api.getProjects(page: 0);
      final firstId = projects.first.id;

      final project = await api.getProjectById(firstId);
      expect(project, isNotNull);
      expect(project!.id, equals(firstId));

      final applied = await api.applyToProject(firstId);
      expect(applied, isTrue);

      final bookmarked = await api.toggleBookmark(firstId);
      expect(bookmarked, isTrue);
    });
  });
}
