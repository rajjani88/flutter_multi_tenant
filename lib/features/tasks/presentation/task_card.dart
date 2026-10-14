import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../organization/domain/role_matrix.dart';
import '../../organization/presentation/organization_providers.dart';
import '../domain/task_entity.dart';
import 'task_form_dialog.dart';
import 'task_providers.dart';

class TaskCard extends ConsumerWidget {
  final TaskEntity task;

  const TaskCard({super.key, required this.task});

  Future<void> _handleQuickStatusChange(
    BuildContext context,
    WidgetRef ref,
    String newStatus,
    String actorUid,
    String actorEmail,
  ) async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      final updated = task.copyWith(status: newStatus);
      await repo.updateTask(
        oldTask: task,
        updatedTask: updated,
        actorId: actorUid,
        actorEmail: actorEmail,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    String actorUid,
    String actorEmail,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.deleteTask(
        task: task,
        actorId: actorUid,
        actorEmail: actorEmail,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${task.title}"'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete task: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).value;
    final currentRole = ref.watch(currentRoleProvider);

    final canUpdate = authUser != null &&
        RoleMatrix.canUpdateTask(
          role: currentRole,
          currentUserId: authUser.uid,
          taskAssigneeId: task.assigneeId,
          taskCreatorId: task.creatorId,
        );

    final canDelete = RoleMatrix.canDeleteTasks(currentRole);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Status badge & Priority badge & Action buttons
            Row(
              children: [
                if (canUpdate)
                  // Quick status selector
                  PopupMenuButton<String>(
                    initialValue: task.status,
                    tooltip: 'Change Status',
                    child: StatusBadge(status: task.status),
                    itemBuilder: (_) => AppConstants.allStatuses.map((s) {
                      return PopupMenuItem(
                        value: s,
                        child: Text(s, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onSelected: (newStatus) {
                      if (newStatus != task.status) {
                        _handleQuickStatusChange(
                          context,
                          ref,
                          newStatus,
                          authUser.uid,
                          authUser.email ?? 'user@nexus.com',
                        );
                      }
                    },
                  )
                else
                  StatusBadge(status: task.status),

                const SizedBox(width: 8),
                PriorityBadge(priority: task.priority),

                const Spacer(),

                // Edit Button
                if (canUpdate)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit Task',
                    color: AppColors.textSecondaryDark,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => TaskFormDialog(taskToEdit: task),
                      );
                    },
                  ),

                // Delete Button
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    tooltip: 'Delete Task',
                    color: AppColors.error.withOpacity(0.8),
                    onPressed: () {
                      if (authUser != null) {
                        _handleDelete(
                          context,
                          ref,
                          authUser.uid,
                          authUser.email ?? 'user@nexus.com',
                        );
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryDark,
              ),
            ),

            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryDark,
                  height: 1.3,
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Bottom Metadata Row: Assignee, Creator, Dates
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Assignee
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_pin_circle_rounded,
                        size: 14, color: AppColors.primaryLight),
                    const SizedBox(width: 4),
                    Text(
                      task.assigneeName != null
                          ? task.assigneeName!
                          : 'Unassigned',
                      style: TextStyle(
                        fontSize: 12,
                        color: task.assigneeName != null
                            ? AppColors.textPrimaryDark
                            : AppColors.textMutedDark,
                      ),
                    ),
                  ],
                ),

                // Due Date
                if (task.dueDate != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_rounded,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat.MMMd().format(task.dueDate!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),

                // Created info
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 14, color: AppColors.textMutedDark),
                    const SizedBox(width: 4),
                    Text(
                      'Created by ${task.creatorName}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMutedDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
