import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/earnings/controllers/earnings_controller.dart';
import 'features/earnings/screens/earnings_screen.dart';
import 'features/projects/controllers/projects_controller.dart';
import 'features/projects/screens/projects_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FunngroAssessmentApp());
}

class FunngroAssessmentApp extends StatefulWidget {
  const FunngroAssessmentApp({super.key});

  @override
  State<FunngroAssessmentApp> createState() => _FunngroAssessmentAppState();
}

class _FunngroAssessmentAppState extends State<FunngroAssessmentApp> {
  late final ProjectsController _projectsController;
  late final EarningsController _earningsController;

  @override
  void initState() {
    super.initState();
    _projectsController = ProjectsController();
    _earningsController = EarningsController();
  }

  @override
  void dispose() {
    _projectsController.dispose();
    _earningsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Funngro Assessment',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: MainNavigationScaffold(
        projectsController: _projectsController,
        earningsController: _earningsController,
      ),
    );
  }
}

class MainNavigationScaffold extends StatefulWidget {
  final ProjectsController projectsController;
  final EarningsController earningsController;

  const MainNavigationScaffold({
    super.key,
    required this.projectsController,
    required this.earningsController,
  });

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      ProjectsScreen(controller: widget.projectsController),
      EarningsScreen(controller: widget.earningsController),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryContainer,
          elevation: 0,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.work_outline_rounded),
              selectedIcon: Icon(Icons.work_rounded, color: AppColors.primary),
              label: 'Projects',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
              ),
              label: 'Earnings',
            ),
          ],
        ),
      ),
    );
  }
}
