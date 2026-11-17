import 'package:flutter/foundation.dart';
import '../../../models/project.dart';
import '../../../services/projects_api.dart';

class ProjectsController extends ChangeNotifier {
  final ProjectsApi _api;

  ProjectsController({ProjectsApi? api}) : _api = api ?? ProjectsApi();

  final List<Project> _projects = [];
  final Set<String> _projectIds = {};

  int _currentPage = 0;
  bool _isLoading = false; // Initial full-page loading state
  bool _isFetchingNextPage = false; // Bottom pagination loading indicator
  bool _hasReachedEnd =
      false; // True when page 8 returns empty or max page reached
  String? _errorMessage; // First-page error state
  String? _paginationErrorMessage; // Subsequent page error state

  // Filter/search properties
  String _selectedCategory = 'All';
  String _searchQuery = '';
  ProjectStatus? _statusFilter;

  // Getters
  List<Project> get projects => List.unmodifiable(_projects);
  bool get isLoading => _isLoading;
  bool get isFetchingNextPage => _isFetchingNextPage;
  bool get hasReachedEnd => _hasReachedEnd;
  String? get errorMessage => _errorMessage;
  String? get paginationErrorMessage => _paginationErrorMessage;
  int get currentPage => _currentPage;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  ProjectStatus? get statusFilter => _statusFilter;

  /// Returns the filtered view of loaded projects
  List<Project> get filteredProjects {
    return _projects.where((project) {
      final matchesCategory =
          _selectedCategory == 'All' ||
          project.category.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesSearch =
          _searchQuery.isEmpty ||
          project.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          project.company.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          project.skills.any(
            (skill) => skill.toLowerCase().contains(_searchQuery.toLowerCase()),
          );

      final matchesStatus =
          _statusFilter == null || project.status == _statusFilter;

      return matchesCategory && matchesSearch && matchesStatus;
    }).toList();
  }

  /// Initial load or full refresh (pull-to-refresh)
  /// Resets pagination and fetches Page 0
  Future<void> loadInitialProjects() async {
    if (_isLoading) return; // Prevent concurrent requests

    _isLoading = true;
    _errorMessage = null;
    _paginationErrorMessage = null;
    notifyListeners();

    try {
      final newProjects = await _api.getProjects(page: 0);

      _projects.clear();
      _projectIds.clear();

      for (final p in newProjects) {
        if (_projectIds.add(p.id)) {
          _projects.add(p);
        }
      }

      _currentPage = 0;
      _hasReachedEnd =
          newProjects.isEmpty || _currentPage >= (ProjectsApi.totalPages - 1);
    } catch (e) {
      _errorMessage = e is ProjectsApiException ? e.message : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads the next page near the bottom of the list (Infinite Scrolling)
  Future<void> fetchNextPage() async {
    // Guards against duplicate requests, existing loadings, or end-of-list
    if (_isLoading ||
        _isFetchingNextPage ||
        _hasReachedEnd ||
        _paginationErrorMessage != null ||
        _currentPage >= (ProjectsApi.totalPages - 1)) {
      return;
    }

    final targetPage = _currentPage + 1;
    _isFetchingNextPage = true;
    _paginationErrorMessage = null;
    notifyListeners();

    try {
      final newProjects = await _api.getProjects(page: targetPage);

      if (newProjects.isEmpty) {
        _hasReachedEnd = true;
      } else {
        int addedCount = 0;
        for (final p in newProjects) {
          // Prevent duplicate project entries
          if (_projectIds.add(p.id)) {
            _projects.add(p);
            addedCount++;
          }
        }

        _currentPage = targetPage;
        if (targetPage >= (ProjectsApi.totalPages - 1) || addedCount == 0) {
          _hasReachedEnd = true;
        }
      }
    } catch (e) {
      // CRITICAL REQUIREMENT: A failed page must NOT remove previously loaded projects!
      _paginationErrorMessage = e is ProjectsApiException
          ? e.message
          : e.toString();
    } finally {
      _isFetchingNextPage = false;
      notifyListeners();
    }
  }

  /// Retries specifically the failed subsequent page without wiping existing list
  Future<void> retryPagination() async {
    if (_isFetchingNextPage || _isLoading) return;

    final targetPage = _currentPage + 1;
    _isFetchingNextPage = true;
    _paginationErrorMessage = null;
    notifyListeners();

    try {
      final newProjects = await _api.getProjects(page: targetPage);

      if (newProjects.isEmpty) {
        _hasReachedEnd = true;
      } else {
        for (final p in newProjects) {
          if (_projectIds.add(p.id)) {
            _projects.add(p);
          }
        }
        _currentPage = targetPage;
        if (targetPage >= (ProjectsApi.totalPages - 1)) {
          _hasReachedEnd = true;
        }
      }
    } catch (e) {
      _paginationErrorMessage = e is ProjectsApiException
          ? e.message
          : e.toString();
    } finally {
      _isFetchingNextPage = false;
      notifyListeners();
    }
  }

  /// Pull-to-refresh resets pagination and loads page 0
  Future<void> refresh() async {
    await loadInitialProjects();
  }

  /// Apply to project
  Future<bool> applyToProject(String projectId) async {
    try {
      final success = await _api.applyToProject(projectId);
      if (success) {
        final index = _projects.indexWhere((p) => p.id == projectId);
        if (index != -1) {
          _projects[index] = _projects[index].copyWith(
            status: ProjectStatus.applied,
            appliedDate: DateTime.now(),
            spotsLeft: (_projects[index].spotsLeft > 1)
                ? _projects[index].spotsLeft - 1
                : 0,
          );
          notifyListeners();
        }
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Toggle bookmark
  Future<void> toggleBookmark(String projectId) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      _projects[index] = _projects[index].copyWith(
        isBookmarked: !_projects[index].isBookmarked,
      );
      notifyListeners();
      await _api.toggleBookmark(projectId);
    }
  }

  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(ProjectStatus? status) {
    if (_statusFilter != status) {
      _statusFilter = status;
      notifyListeners();
    }
  }
}
