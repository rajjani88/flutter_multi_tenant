import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/role_badge.dart';
import '../../organization/presentation/organization_providers.dart';
import '../../organization/presentation/organization_switcher_sheet.dart';
import 'task_card.dart';
import 'task_filter_bar.dart';
import 'task_form_dialog.dart';
import 'task_providers.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrgAsync = ref.watch(activeOrganizationProvider);
    final rawTasksAsync = ref.watch(rawTasksStreamProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);
    final statusCounts = ref.watch(taskStatusCountsProvider);
    final currentRole = ref.watch(currentRoleProvider);
    final canCreate = ref.watch(canCreateTaskProvider);
    final filter = ref.watch(taskFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => const OrganizationSwitcherSheet(),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.corporate_fare_rounded,
                    size: 20, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Text(
                  activeOrgAsync.value?.name ?? 'Select Workspace',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: AppColors.textSecondaryDark),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: RoleBadge(role: currentRole),
          ),
        ],
      ),
      body: Column(
        children: [
          // Metrics Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.darkSurface.withOpacity(0.5),
            child: Row(
              children: [
                _MetricItem(label: 'Total', count: statusCounts['Total'] ?? 0, color: AppColors.primaryLight),
                const SizedBox(width: 14),
                _MetricItem(label: 'To Do', count: statusCounts['To Do'] ?? 0, color: AppColors.statusToDo),
                const SizedBox(width: 14),
                _MetricItem(label: 'In Progress', count: statusCounts['In Progress'] ?? 0, color: AppColors.statusInProgress),
                const SizedBox(width: 14),
                _MetricItem(label: 'Done', count: statusCounts['Done'] ?? 0, color: AppColors.statusDone),
              ],
            ),
          ),

          // Tandem Multi-Filter Bar
          const TaskFilterBar(),

          // Task Feed
          Expanded(
            child: rawTasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No Tasks Yet',
                    description: 'Get started by creating your first workspace task.',
                    actionLabel: canCreate ? 'Create Task' : null,
                    onAction: canCreate
                        ? () {
                            showDialog(
                              context: context,
                              builder: (_) => const TaskFormDialog(),
                            );
                          }
                        : null,
                  );
                }

                if (filteredTasks.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.filter_list_off_rounded,
                    title: 'No Matching Tasks',
                    description: 'No tasks match your selected filter criteria.',
                    actionLabel: 'Reset Filters',
                    onAction: () {
                      ref.read(taskFilterProvider.notifier).setFilter(filter.copyWith(
                        clearStatus: true,
                        clearPriority: true,
                        clearAssignee: true,
                        clearDateRange: true,
                        searchQuery: '',
                      ));
                    },
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return TaskCard(task: filteredTasks[index]);
                  },
                );
              },
              loading: () => const AppLoadingIndicator(message: 'Syncing real-time tasks...'),
              error: (err, _) => AppErrorWidget(
                error: err,
                onRetry: () => ref.refresh(rawTasksStreamProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const TaskFormDialog(),
                );
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_task_rounded, color: Colors.white),
              label: const Text('New Task',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
