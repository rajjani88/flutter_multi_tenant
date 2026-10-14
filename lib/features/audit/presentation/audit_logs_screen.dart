import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../organization/domain/role_matrix.dart';
import '../../organization/presentation/organization_providers.dart';
import '../domain/audit_log_entity.dart';
import 'audit_providers.dart';

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(currentRoleProvider);
    final canView = RoleMatrix.canViewAuditLogs(currentRole);

    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Audit Trail')),
        body: const AppErrorWidget(
          error: 'permission-denied',
          customMessage:
              'Audit logs contain sensitive workspace history and are restricted to Owners, Admins, and Managers.',
        ),
      );
    }

    final auditLogsAsync = ref.watch(auditLogsStreamProvider);
    final activeOrg = ref.watch(activeOrganizationProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Audit Trail & History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (activeOrg != null)
              Text(
                'Organization: ${activeOrg.name} • Immutable Log',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
              ),
          ],
        ),
      ),
      body: auditLogsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.history_rounded,
              title: 'No Audit Records',
              description: 'Activity records will automatically appear here as team operations occur.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _AuditEntryCard(log: logs[index]);
            },
          );
        },
        loading: () => const AppLoadingIndicator(message: 'Loading immutable audit trail...'),
        error: (err, _) => AppErrorWidget(
          error: err,
          onRetry: () => ref.refresh(auditLogsStreamProvider),
        ),
      ),
    );
  }
}

class _AuditEntryCard extends StatefulWidget {
  final AuditLogEntity log;

  const _AuditEntryCard({required this.log});

  @override
  State<_AuditEntryCard> createState() => _AuditEntryCardState();
}

class _AuditEntryCardState extends State<_AuditEntryCard> {
  bool _isExpanded = false;

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'task_created':
        return Icons.add_task_rounded;
      case 'task_updated':
        return Icons.edit_note_rounded;
      case 'task_deleted':
        return Icons.delete_outline_rounded;
      case 'member_invited':
        return Icons.person_add_rounded;
      case 'member_removed':
        return Icons.person_remove_rounded;
      case 'role_changed':
        return Icons.security_rounded;
      case 'org_created':
        return Icons.business_rounded;
      case 'settings_updated':
        return Icons.settings_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'task_created':
      case 'org_created':
        return AppColors.success;
      case 'task_updated':
      case 'role_changed':
      case 'settings_updated':
        return AppColors.primaryLight;
      case 'task_deleted':
      case 'member_removed':
        return AppColors.error;
      case 'member_invited':
        return AppColors.secondary;
      default:
        return AppColors.textSecondaryDark;
    }
  }

  String _formatActionTitle(String action) {
    return action
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final color = _getActionColor(log.action);
    final icon = _getActionIcon(log.action);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder, width: 1),
      ),
      child: InkWell(
        onTap: log.details.isNotEmpty
            ? () => setState(() => _isExpanded = !_isExpanded)
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatActionTitle(log.action),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Actor: ${log.actorEmail}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, h:mm a').format(log.timestamp),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMutedDark,
                    ),
                  ),
                  if (log.details.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.textMutedDark,
                    ),
                  ],
                ],
              ),
              if (_isExpanded && log.details.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Change Metadata & Parameters:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMutedDark,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: log.details.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
