import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/task_repository.dart';
import '../domain/task_entity.dart';
import '../domain/task_filter.dart';
import '../../organization/presentation/organization_providers.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

/// Raw real-time task stream for active tenant
final rawTasksStreamProvider = StreamProvider<List<TaskEntity>>((ref) {
  final activeOrgId = ref.watch(activeOrganizationIdProvider);
  if (activeOrgId == null) return Stream.value([]);
  final repo = ref.watch(taskRepositoryProvider);
  return repo.streamTasks(activeOrgId);
});

/// Current active task filter state notifier
class TaskFilterNotifier extends Notifier<TaskFilter> {
  @override
  TaskFilter build() => const TaskFilter();

  void setFilter(TaskFilter filter) {
    state = filter;
  }
}

final taskFilterProvider =
    NotifierProvider<TaskFilterNotifier, TaskFilter>(() => TaskFilterNotifier());

/// Reactive filtered tasks matching the multi-filter criteria in tandem
final filteredTasksProvider = Provider<List<TaskEntity>>((ref) {
  final tasksAsync = ref.watch(rawTasksStreamProvider);
  final filter = ref.watch(taskFilterProvider);

  return tasksAsync.when(
    data: (tasks) => filter.apply(tasks),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Task counts for status metrics
final taskStatusCountsProvider = Provider<Map<String, int>>((ref) {
  final tasksAsync = ref.watch(rawTasksStreamProvider);
  return tasksAsync.when(
    data: (tasks) {
      final counts = {'To Do': 0, 'In Progress': 0, 'Done': 0, 'Total': tasks.length};
      for (final t in tasks) {
        counts[t.status] = (counts[t.status] ?? 0) + 1;
      }
      return counts;
    },
    loading: () => {'To Do': 0, 'In Progress': 0, 'Done': 0, 'Total': 0},
    error: (_, __) => {'To Do': 0, 'In Progress': 0, 'Done': 0, 'Total': 0},
  );
});
