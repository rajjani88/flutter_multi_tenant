import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../organization/presentation/organization_providers.dart';
import '../domain/task_filter.dart';
import 'task_providers.dart';

class TaskFilterBar extends ConsumerWidget {
  const TaskFilterBar({super.key});

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref, TaskFilter filter) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: (filter.startDate != null && filter.endDate != null)
          ? DateTimeRange(start: filter.startDate!, end: filter.endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.darkSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(taskFilterProvider.notifier).setFilter(filter.copyWith(
        startDate: picked.start,
        endDate: picked.end,
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterProvider);
    final membersAsync = ref.watch(organizationMembersProvider);
    final members = membersAsync.value ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Search bar + Date Range picker + Clear filters
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search tasks by title, description...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      suffixIcon: filter.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                ref.read(taskFilterProvider.notifier).setFilter(
                                      filter.copyWith(searchQuery: ''),
                                    );
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      ref.read(taskFilterProvider.notifier).setFilter(
                            filter.copyWith(searchQuery: val),
                          );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Date Range Filter Button (Pre-built for Live Modification assessment!)
              OutlinedButton.icon(
                onPressed: () => _pickDateRange(context, ref, filter),
                icon: Icon(
                  Icons.date_range_rounded,
                  size: 16,
                  color: (filter.startDate != null) ? AppColors.primaryLight : AppColors.textSecondaryDark,
                ),
                label: Text(
                  filter.startDate != null
                      ? '${DateFormat.MMMd().format(filter.startDate!)} - ${DateFormat.MMMd().format(filter.endDate!)}'
                      : 'Date Range',
                  style: TextStyle(
                    fontSize: 12,
                    color: filter.startDate != null ? AppColors.primaryLight : AppColors.textPrimaryDark,
                    fontWeight: filter.startDate != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  side: BorderSide(
                    color: filter.startDate != null ? AppColors.primary : AppColors.darkBorder,
                  ),
                ),
              ),

              if (filter.hasActiveFilters) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear All Filters',
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 18, color: AppColors.error),
                  onPressed: () {
                    ref.read(taskFilterProvider.notifier).setFilter(const TaskFilter());
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Status, Priority, Assignee Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status Filter Chips
                const Text('Status: ', style: TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                const SizedBox(width: 4),
                _FilterChip(
                  label: 'All',
                  isSelected: filter.status == null || filter.status == 'All',
                  onTap: () => ref.read(taskFilterProvider.notifier).setFilter(
                        filter.copyWith(status: 'All'),
                      ),
                ),
                ...AppConstants.allStatuses.map((s) {
                  return _FilterChip(
                    label: s,
                    isSelected: filter.status == s,
                    onTap: () => ref.read(taskFilterProvider.notifier).setFilter(
                          filter.copyWith(status: s),
                        ),
                  );
                }),
                const SizedBox(width: 12),
                Container(width: 1, height: 18, color: AppColors.darkBorder),
                const SizedBox(width: 12),

                // Priority Filter Chips
                const Text('Priority: ', style: TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                const SizedBox(width: 4),
                _FilterChip(
                  label: 'All',
                  isSelected: filter.priority == null || filter.priority == 'All',
                  onTap: () => ref.read(taskFilterProvider.notifier).setFilter(
                        filter.copyWith(priority: 'All'),
                      ),
                ),
                ...AppConstants.allPriorities.map((p) {
                  return _FilterChip(
                    label: p,
                    isSelected: filter.priority == p,
                    onTap: () => ref.read(taskFilterProvider.notifier).setFilter(
                          filter.copyWith(priority: p),
                        ),
                  );
                }),
                const SizedBox(width: 12),
                Container(width: 1, height: 18, color: AppColors.darkBorder),
                const SizedBox(width: 12),

                // Assignee Filter
                const Text('Assignee: ', style: TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                const SizedBox(width: 4),
                _FilterChip(
                  label: 'All',
                  isSelected: filter.assigneeId == null || filter.assigneeId == 'All',
                  onTap: () => ref.read(taskFilterProvider.notifier).setFilter(
                        filter.copyWith(assigneeId: 'All'),
                      ),
                ),
                _FilterChip(
                  label: 'Unassigned',
                  isSelected: filter.assigneeId == 'unassigned',
                  onTap: () => ref.read(taskFilterProvider.notifier).setFilter(
                        filter.copyWith(assigneeId: 'unassigned'),
                      ),
                ),
                ...members.map((m) {
                  return _FilterChip(
                    label: m.displayName,
                    isSelected: filter.assigneeId == m.userId,
                    onTap: () => ref.read(taskFilterProvider.notifier).setFilter(
                          filter.copyWith(assigneeId: m.userId),
                        ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.2)
                : AppColors.darkBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.darkBorder,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppColors.primaryLight : AppColors.textSecondaryDark,
            ),
          ),
        ),
      ),
    );
  }
}
