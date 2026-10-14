import 'package:equatable/equatable.dart';
import 'task_entity.dart';

class TaskFilter extends Equatable {
  final String? status; // null or 'All' means any
  final String? priority; // null or 'All' means any
  final String? assigneeId; // null or 'All' means any, 'unassigned' means null
  final DateTime? startDate; // Date range filter
  final DateTime? endDate;
  final String searchQuery;

  const TaskFilter({
    this.status,
    this.priority,
    this.assigneeId,
    this.startDate,
    this.endDate,
    this.searchQuery = '',
  });

  bool get hasActiveFilters =>
      (status != null && status != 'All') ||
      (priority != null && priority != 'All') ||
      (assigneeId != null && assigneeId != 'All') ||
      startDate != null ||
      endDate != null ||
      searchQuery.trim().isNotEmpty;

  TaskFilter copyWith({
    String? status,
    String? priority,
    String? assigneeId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool clearStatus = false,
    bool clearPriority = false,
    bool clearAssignee = false,
    bool clearDateRange = false,
  }) {
    return TaskFilter(
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
      startDate: clearDateRange ? null : (startDate ?? this.startDate),
      endDate: clearDateRange ? null : (endDate ?? this.endDate),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Evaluates tasks in tandem with status, priority, assignee, date-range and search query
  List<TaskEntity> apply(List<TaskEntity> tasks) {
    return tasks.where((task) {
      // 1. Status filter
      if (status != null && status != 'All' && task.status != status) {
        return false;
      }

      // 2. Priority filter
      if (priority != null && priority != 'All' && task.priority != priority) {
        return false;
      }

      // 3. Assignee filter
      if (assigneeId != null && assigneeId != 'All') {
        if (assigneeId == 'unassigned') {
          if (task.assigneeId != null && task.assigneeId!.isNotEmpty) {
            return false;
          }
        } else if (task.assigneeId != assigneeId) {
          return false;
        }
      }

      // 4. Date range filter (in tandem)
      if (startDate != null) {
        final startOfDay = DateTime(startDate!.year, startDate!.month, startDate!.day);
        if (task.createdAt.isBefore(startOfDay)) {
          return false;
        }
      }

      if (endDate != null) {
        final endOfDay = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
        if (task.createdAt.isAfter(endOfDay)) {
          return false;
        }
      }

      // 5. Search query
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesTitle = task.title.toLowerCase().contains(query);
        final matchesDesc = task.description.toLowerCase().contains(query);
        final matchesAssignee = task.assigneeName?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesDesc && !matchesAssignee) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  List<Object?> get props => [
        status,
        priority,
        assigneeId,
        startDate,
        endDate,
        searchQuery,
      ];
}
