import 'package:flutter_test/flutter_test.dart';
import 'package:funngro_assessment/features/projects/controllers/projects_controller.dart';
import 'package:funngro_assessment/models/project.dart';
import 'package:funngro_assessment/services/projects_api.dart';

class MockDeterministicProjectsApi extends ProjectsApi {
  bool failNextRequest = false;
  int getProjectsCallCount = 0;
  List<int> requestedPages = [];

  MockDeterministicProjectsApi()
    : super(enableRandomFailures: false, simulatedLatency: Duration.zero);

  @override
  Future<List<Project>> getProjects({required int page}) async {
    getProjectsCallCount++;
    requestedPages.add(page);

    if (failNextRequest) {
      throw ProjectsApiException('Simulated failure for page $page');
    }
    return super.getProjects(page: page);
  }
}

void main() {
  group('ProjectsController Pagination & Resilience Tests', () {
    late MockDeterministicProjectsApi mockApi;
    late ProjectsController controller;

    setUp(() {
      mockApi = MockDeterministicProjectsApi();
      controller = ProjectsController(api: mockApi);
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial loading state and successful page 0 retrieval', () async {
      expect(controller.projects, isEmpty);
      expect(controller.isLoading, isFalse);

      final future = controller.loadInitialProjects();
      expect(controller.isLoading, isTrue);

      await future;

      expect(controller.isLoading, isFalse);
      expect(controller.projects.length, equals(20));
      expect(controller.currentPage, equals(0));
      expect(controller.errorMessage, isNull);
      expect(controller.hasReachedEnd, isFalse);
    });

    test(
      'Pagination state: fetchNextPage appends 20 projects for page 1',
      () async {
        await controller.loadInitialProjects();
        expect(controller.projects.length, equals(20));

        await controller.fetchNextPage();

        expect(controller.projects.length, equals(40));
        expect(controller.currentPage, equals(1));
        expect(mockApi.requestedPages, equals([0, 1]));
      },
    );

    test(
      'Preserving existing projects after a failed next-page request',
      () async {
        // 1. Successfully load page 0
        await controller.loadInitialProjects();
        expect(controller.projects.length, equals(20));
        final initialProjects = List<Project>.from(controller.projects);

        // 2. Set API to fail on next request (page 1)
        mockApi.failNextRequest = true;
        await controller.fetchNextPage();

        // CRITICAL REQUIREMENT: Existing 20 projects must be preserved!
        expect(controller.projects.length, equals(20));
        expect(controller.projects, equals(initialProjects));
        expect(
          controller.paginationErrorMessage,
          contains('Simulated failure'),
        );
        expect(controller.isFetchingNextPage, isFalse);
      },
    );

    test(
      'Retry behavior: retryPagination requests failed page without resetting list',
      () async {
        await controller.loadInitialProjects();

        // Trigger failure on page 1
        mockApi.failNextRequest = true;
        await controller.fetchNextPage();
        expect(controller.paginationErrorMessage, isNotNull);
        expect(controller.projects.length, equals(20));

        // Resolve failure and retry
        mockApi.failNextRequest = false;
        await controller.retryPagination();

        expect(controller.paginationErrorMessage, isNull);
        expect(controller.projects.length, equals(40));
        expect(controller.currentPage, equals(1));
        expect(mockApi.requestedPages, equals([0, 1, 1])); // 1 was re-requested
      },
    );

    test(
      'Refresh behavior: refresh() resets pagination and loads page 0',
      () async {
        await controller.loadInitialProjects();
        await controller.fetchNextPage();
        expect(controller.projects.length, equals(40));
        expect(controller.currentPage, equals(1));

        await controller.refresh();

        expect(controller.currentPage, equals(0));
        expect(controller.projects.length, equals(20));
      },
    );

    test('Preventing duplicate concurrent API requests', () async {
      await controller.loadInitialProjects();
      final callCountBefore = mockApi.getProjectsCallCount;

      // Fire multiple simultaneous calls
      final future1 = controller.fetchNextPage();
      final future2 = controller.fetchNextPage();
      final future3 = controller.fetchNextPage();

      await Future.wait([future1, future2, future3]);

      // Only one pagination request should have gone through
      expect(mockApi.getProjectsCallCount, equals(callCountBefore + 1));
      expect(controller.projects.length, equals(40));
    });

    test(
      'Prevents requesting pages beyond page 7 and sets hasReachedEnd',
      () async {
        await controller.loadInitialProjects(); // page 0

        for (int i = 1; i <= 7; i++) {
          await controller.fetchNextPage();
        }

        expect(controller.currentPage, equals(7));
        expect(controller.projects.length, equals(160));
        expect(controller.hasReachedEnd, isTrue);

        // Subsequent fetchNextPage should be ignored
        final callCount = mockApi.getProjectsCallCount;
        await controller.fetchNextPage();
        expect(mockApi.getProjectsCallCount, equals(callCount));
      },
    );
  });
}
