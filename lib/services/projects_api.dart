import 'dart:math';
import '../models/project.dart';

class ProjectsApiException implements Exception {
  final String message;
  final int? statusCode;

  const ProjectsApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ProjectsApiException: $message (status: $statusCode)';
}

class ProjectsApi {
  static const int pageSize = 20;
  static const int totalPages =
      8; // Pages 0 through 7 are valid; page 8 is empty
  static const int totalProjects = 160;

  final bool enableRandomFailures;
  final bool? forceFailure;
  final Duration simulatedLatency;
  final Random _random;

  // The complete synthetic catalog of 160 projects
  late final List<Project> _allProjects;

  ProjectsApi({
    this.enableRandomFailures = true,
    this.forceFailure,
    this.simulatedLatency = const Duration(milliseconds: 900),
    Random? random,
  }) : _random = random ?? Random() {
    _allProjects = _generateProjects();
  }

  static List<Project> _generateProjects() {
    final companies = [
      'EcoVibe Organics',
      'NextGen Ventures',
      'SkillUp Academy',
      'FinBud Fintech',
      'YouthPulse Insights',
      'GameCraft Studios',
      'ByteCraft Labs',
      'Zenith Design',
      'AeroTech Labs',
      'Urban Threads',
      'Nova AI',
      'CloudPeak Media',
      'Spark Robotics',
      'Alpha Marketing',
      'PixelWorks Studio',
      'HyperGrowth Co',
    ];

    final roles = [
      'Social Media Content Creator',
      'Instagram Reels Video Editor',
      'SEO Blog Article Writer',
      'Figma Mobile App UI Designer',
      'Flutter App Quality Assurance Tester',
      'Youth Campus Market Researcher',
      'YouTube Shorts Thumbnail Artist',
      'Graphic Designer for Brand Kit',
      'Python Data Web Scraping Gig',
      'Community Discord Moderator',
    ];

    final categories = [
      'Social Media',
      'Content Writing',
      'Graphic Design',
      'Video Editing',
      'Web Development',
      'Market Research',
    ];

    final skillsPool = [
      ['Canva', 'Instagram', 'Copywriting'],
      ['Premiere Pro', 'CapCut', 'Sound Design'],
      ['SEO', 'Blog Writing', 'Grammarly'],
      ['Figma', 'UI/UX', 'Wireframing'],
      ['Flutter', 'Bug Reporting', 'QA Testing'],
      ['Surveys', 'Analytics', 'Interviews'],
      ['Photoshop', 'Branding', 'Typography'],
      ['Python', 'BeautifulSoup', 'Excel'],
    ];

    final list = <Project>[];
    for (int i = 0; i < totalProjects; i++) {
      final comp = companies[i % companies.length];
      final role = roles[i % roles.length];
      final cat = categories[i % categories.length];
      final skills = skillsPool[i % skillsPool.length];
      final payout =
          1500.0 +
          ((i * 137) % 3500); // Varied payouts between ₹1,500 and ₹5,000

      list.add(
        Project(
          id: 'proj-${(i + 1).toString().padLeft(3, '0')}',
          title: '$role #${i + 1}',
          company: comp,
          payout: payout,
          category: cat,
          duration: '${((i % 3) + 1)} week${((i % 3) + 1) > 1 ? 's' : ''}',
          description:
              'Exciting freelance gig for teen creators: collaborate with $comp to deliver high-impact $cat deliverables. Clear guidelines and mentorship provided.',
          skills: skills,
          deadline: DateTime.now().add(Duration(days: ((i % 14) + 2))),
          spotsLeft: ((i % 4) + 1),
          status: i == 3 ? ProjectStatus.applied : ProjectStatus.open,
        ),
      );
    }
    return list;
  }

  /// Fetches a page of projects with fake API constraints:
  /// - 20 projects per page.
  /// - Available pages: 0 to 7.
  /// - Total projects: 160.
  /// - Latency: 900ms.
  /// - Approximately 1 in 5 requests (20%) fail randomly with an exception.
  /// - Page 8 (or above) returns an empty list.
  Future<List<Project>> getProjects({required int page}) async {
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }

    // Check forced failure or ~1 in 5 random failure
    final shouldFail =
        forceFailure ??
        (enableRandomFailures &&
            (_random.nextInt(5) == 0)); // 20% failure probability

    if (shouldFail) {
      throw const ProjectsApiException(
        'Simulated network timeout (1-in-5 failure). Please try again.',
        statusCode: 503,
      );
    }

    // Page 8 or beyond returns an empty list
    if (page >= totalPages || page < 0) {
      return <Project>[];
    }

    final startIndex = page * pageSize;
    final endIndex = min(startIndex + pageSize, _allProjects.length);

    if (startIndex >= _allProjects.length) {
      return <Project>[];
    }

    return _allProjects.sublist(startIndex, endIndex);
  }

  /// Single project lookup
  Future<Project?> getProjectById(String id) async {
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }
    try {
      return _allProjects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Apply to project
  Future<bool> applyToProject(String projectId) async {
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }
    final index = _allProjects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final current = _allProjects[index];
      _allProjects[index] = current.copyWith(
        status: ProjectStatus.applied,
        appliedDate: DateTime.now(),
        spotsLeft: current.spotsLeft > 1 ? current.spotsLeft - 1 : 0,
      );
      return true;
    }
    return false;
  }

  /// Toggle bookmark
  Future<bool> toggleBookmark(String projectId) async {
    final index = _allProjects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      _allProjects[index] = _allProjects[index].copyWith(
        isBookmarked: !_allProjects[index].isBookmarked,
      );
      return true;
    }
    return false;
  }
}
