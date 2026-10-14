import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../organization/domain/member_entity.dart';
import '../../organization/domain/role_matrix.dart';
import '../../organization/presentation/organization_providers.dart';
import '../domain/task_entity.dart';
import 'task_providers.dart';

class TaskFormDialog extends ConsumerStatefulWidget {
  final TaskEntity? taskToEdit;

  const TaskFormDialog({super.key, this.taskToEdit});

  @override
  ConsumerState<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends ConsumerState<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _status;
  late String _priority;
  String? _assigneeId;
  String? _assigneeName;
  DateTime? _dueDate;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _status = task?.status ?? AppConstants.statusToDo;
    _priority = task?.priority ?? AppConstants.priorityMedium;
    _assigneeId = task?.assigneeId;
    _assigneeName = task?.assigneeName;
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final activeOrgId = ref.read(activeOrganizationIdProvider);
    final authUser = ref.read(authStateProvider).value;
    final currentRole = ref.read(currentRoleProvider);

    if (activeOrgId == null || authUser == null) return;

    // RBAC validation: Viewers cannot create or update tasks
    if (currentRole == AppRole.viewer) {
      setState(() => _errorMessage = 'Viewers have read-only access.');
      return;
    }

    // RBAC validation: Members cannot assign tasks to another member
    if (currentRole == AppRole.member) {
      if (_assigneeId != null && _assigneeId != authUser.uid) {
        setState(() => _errorMessage =
            'Members cannot assign tasks to other members (must be assigned to yourself or left unassigned).');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(taskRepositoryProvider);

      if (isEditing) {
        final oldTask = widget.taskToEdit!;
        final updated = oldTask.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          status: _status,
          priority: _priority,
          assigneeId: _assigneeId,
          assigneeName: _assigneeName,
          dueDate: _dueDate,
        );

        await repo.updateTask(
          oldTask: oldTask,
          updatedTask: updated,
          actorId: authUser.uid,
          actorEmail: authUser.email ?? 'actor@nexus.com',
        );

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await repo.createTask(
          orgId: activeOrgId,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          status: _status,
          priority: _priority,
          assigneeId: _assigneeId,
          assigneeName: _assigneeName,
          creatorId: authUser.uid,
          creatorName: authUser.displayName ?? authUser.email ?? 'User',
          creatorEmail: authUser.email ?? 'user@nexus.com',
          dueDate: _dueDate,
        );

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task created successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst(RegExp(r'\[.*?\]'), '').trim();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(currentRoleProvider);
    final members = ref.watch(organizationMembersProvider).value ?? [];
    final authUser = ref.watch(authStateProvider).value;

    // Determine assignee options based on role
    // Members can only assign to themselves or unassigned
    final canAssignOthers = RoleMatrix.canAssignTasks(currentRole);

    // Build deduplicated map of eligible members
    final eligibleMembers = <String, MemberEntity>{};
    for (final m in members) {
      if (canAssignOthers || m.userId == authUser?.uid) {
        eligibleMembers[m.userId] = m;
      }
    }

    // If editing a task whose existing assignee is not in eligibleMembers,
    // retain them in the map so the Dropdown value always has a matching DropdownMenuItem
    if (_assigneeId != null && !eligibleMembers.containsKey(_assigneeId)) {
      eligibleMembers[_assigneeId!] = MemberEntity(
        userId: _assigneeId!,
        email: '',
        displayName: (_assigneeName != null && _assigneeName!.trim().isNotEmpty)
            ? _assigneeName!
            : 'Assigned Member',
        role: AppRole.member,
        joinedAt: DateTime.now(),
      );
    }

    final selectedAssigneeId = (_assigneeId != null && eligibleMembers.containsKey(_assigneeId))
        ? _assigneeId
        : null;

    final assigneeItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('Unassigned', style: TextStyle(fontSize: 13)),
      ),
      ...eligibleMembers.values.map((m) {
        return DropdownMenuItem<String?>(
          value: m.userId,
          child: Text(
            '${m.displayName} (${m.role.value})',
            style: const TextStyle(fontSize: 13),
          ),
        );
      }),
    ];

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note_rounded : Icons.add_task_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'Edit Task' : 'Create New Task',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title
                const Text('Task Title',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  autofocus: !isEditing,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Implement OAuth Flow, Audit Security Rules',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Title is required';
                    if (val.trim().length > 200) return 'Title cannot exceed 200 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                const Text('Description',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Detailed task specifications and acceptance criteria...',
                  ),
                ),
                const SizedBox(height: 16),

                // Row for Status and Priority
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: AppConstants.allStatuses.contains(_status)
                                ? _status
                                : AppConstants.statusToDo,
                            dropdownColor: AppColors.darkSurface,
                            items: AppConstants.allStatuses.map((s) {
                              return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _status = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Priority',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: AppConstants.allPriorities.contains(_priority)
                                ? _priority
                                : AppConstants.priorityMedium,
                            dropdownColor: AppColors.darkSurface,
                            items: AppConstants.allPriorities.map((p) {
                              return DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _priority = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Assignee selection (Role gated)
                const Text('Assignee',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: selectedAssigneeId,
                  dropdownColor: AppColors.darkSurface,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    helperText: !canAssignOthers
                        ? 'Members can only assign to themselves or unassigned.'
                        : null,
                  ),
                  items: assigneeItems,
                  onChanged: (val) {
                    setState(() {
                      _assigneeId = val;
                      if (val == null) {
                        _assigneeName = null;
                      } else {
                        final found = eligibleMembers[val];
                        _assigneeName = found?.displayName;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Due Date Selector
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 3)),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          if (picked != null) {
                            setState(() => _dueDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(
                          _dueDate != null
                              ? 'Due: ${DateFormat.yMMMd().format(_dueDate!)}'
                              : 'Set Due Date',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    if (_dueDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _dueDate = null),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(isEditing ? 'Save Changes' : 'Create Task'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
