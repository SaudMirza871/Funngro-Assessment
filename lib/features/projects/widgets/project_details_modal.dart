import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/project.dart';
import '../../../widgets/status_chip.dart';
import '../controllers/projects_controller.dart';

class ProjectDetailsModal extends StatelessWidget {
  final Project project;
  final ProjectsController controller;

  const ProjectDetailsModal({
    super.key,
    required this.project,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  project.company.isNotEmpty
                      ? project.company[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.company,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ProjectStatusChip(status: project.status),
            ],
          ),
          const SizedBox(height: 20),

          // Highlights Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ModalHighlight(
                  label: 'Payout',
                  value: Formatters.formatCurrency(project.payout),
                  icon: Icons.payments_outlined,
                ),
                _ModalHighlight(
                  label: 'Duration',
                  value: project.duration,
                  icon: Icons.timer_outlined,
                ),
                _ModalHighlight(
                  label: 'Deadline',
                  value: Formatters.formatShortDate(project.deadline),
                  icon: Icons.calendar_today_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // About Section
          const Text(
            'About Project',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            project.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Skills
          if (project.skills.isNotEmpty) ...[
            const Text(
              'Required Skills',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: project.skills.map((skill) {
                return Chip(
                  label: Text(skill),
                  backgroundColor: AppColors.backgroundLight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Apply CTA
          SizedBox(
            width: double.infinity,
            height: 48,
            child: project.status == ProjectStatus.open
                ? ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final success = await controller.applyToProject(
                        project.id,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Successfully applied to ${project.title}!'
                                  : 'Failed to submit application.',
                            ),
                            backgroundColor: success
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Apply for this Project',
                      style: TextStyle(fontSize: 15),
                    ),
                  )
                : OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close (${project.status.label})'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ModalHighlight extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ModalHighlight({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
