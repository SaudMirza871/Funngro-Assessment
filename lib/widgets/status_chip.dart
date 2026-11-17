import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/project.dart';
import '../models/earning.dart';

class ProjectStatusChip extends StatelessWidget {
  final ProjectStatus status;

  const ProjectStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status.label;

    switch (status) {
      case ProjectStatus.open:
        bg = AppColors.successContainer;
        fg = AppColors.success;
        break;
      case ProjectStatus.applied:
        bg = AppColors.primaryContainer;
        fg = AppColors.primary;
        break;
      case ProjectStatus.inProgress:
        bg = AppColors.warningContainer;
        fg = AppColors.warning;
        break;
      case ProjectStatus.completed:
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF7C3AED);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class EarningStatusChip extends StatelessWidget {
  final EarningStatus status;

  const EarningStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status.label;

    switch (status) {
      case EarningStatus.credited:
        bg = AppColors.successContainer;
        fg = AppColors.success;
        break;
      case EarningStatus.pending:
        bg = AppColors.warningContainer;
        fg = AppColors.warning;
        break;
      case EarningStatus.withdrawn:
        bg = AppColors.backgroundLight;
        fg = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
