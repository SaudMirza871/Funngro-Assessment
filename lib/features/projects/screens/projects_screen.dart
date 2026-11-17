import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../models/project.dart';
import '../../../widgets/custom_search_bar.dart';
import '../../../widgets/empty_view.dart';
import '../controllers/projects_controller.dart';
import '../widgets/pagination_indicator.dart';
import '../widgets/project_card.dart';
import '../widgets/project_details_modal.dart';

class ProjectsScreen extends StatefulWidget {
  final ProjectsController controller;

  const ProjectsScreen({super.key, required this.controller});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initial fetch of page 0
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.projects.isEmpty && !widget.controller.isLoading) {
        widget.controller.loadInitialProjects();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Trigger pagination when within 250px of the bottom
    final threshold = _scrollController.position.maxScrollExtent - 250;
    if (_scrollController.position.pixels >= threshold) {
      widget.controller.fetchNextPage();
    }
  }

  void _openDetails(BuildContext context, Project project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ProjectDetailsModal(project: project, controller: widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Projects',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh projects',
                onPressed: controller.isLoading ? null : controller.refresh,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.refresh,
            child: _buildBody(controller),
          ),
        );
      },
    );
  }

  Widget _buildBody(ProjectsController controller) {
    // 1. Initial Page 0 Loading State
    if (controller.isLoading && controller.projects.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Fetching opportunities...',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // 2. Initial Page 0 Error State with Retry
    if (controller.errorMessage != null && controller.projects.isEmpty) {
      return EmptyView(
        icon: Icons.cloud_off_rounded,
        title: 'Failed to load projects',
        message: controller.errorMessage!,
        actionLabel: 'Retry',
        onAction: controller.loadInitialProjects,
      );
    }

    // 3. Search & Filter Bar + Project List
    final filtered = controller.filteredProjects;

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: CustomSearchBar(
              controller: _searchController,
              hintText: 'Search roles, skills, or companies...',
              onChanged: controller.setSearchQuery,
              onClear: () => controller.setSearchQuery(''),
            ),
          ),
        ),

        // Categories Chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: AppConstants.categories.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = AppConstants.categories[index];
                final isSelected = controller.selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => controller.setCategory(cat),
                );
              },
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 6)),

        // Empty state when search/filter returns zero items
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(
              icon: Icons.search_off_rounded,
              title: 'No Matching Projects',
              message:
                  'No active projects found for "${controller.searchQuery}". Try a different search term.',
              actionLabel: 'Clear Filters',
              onAction: () {
                _searchController.clear();
                controller.setSearchQuery('');
                controller.setCategory('All');
                controller.setStatusFilter(null);
              },
            ),
          )
        else
          // Lazy Virtualized Project Cards
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final project = filtered[index];
              return ProjectCard(
                project: project,
                onTap: () => _openDetails(context, project),
                onBookmark: () => controller.toggleBookmark(project.id),
                onApply: () async {
                  final success = await controller.applyToProject(project.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Application submitted for "${project.title}"!'
                              : 'Failed to apply.',
                        ),
                        backgroundColor: success
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    );
                  }
                },
              );
            }, childCount: filtered.length),
          ),

        // 4. Pagination Footer (Loading / Error with Retry / End of List)
        if (filtered.isNotEmpty &&
            controller.searchQuery.isEmpty &&
            controller.selectedCategory == 'All')
          SliverToBoxAdapter(
            child: PaginationIndicator(
              isFetchingNextPage: controller.isFetchingNextPage,
              errorMessage: controller.paginationErrorMessage,
              hasReachedEnd: controller.hasReachedEnd,
              onRetry: controller.retryPagination,
            ),
          )
        else
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
