import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/role_badge.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/member_entity.dart';
import '../domain/role_matrix.dart';
import 'invite_member_dialog.dart';
import 'organization_providers.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrg = ref.watch(activeOrganizationProvider).value;
    final membersAsync = ref.watch(organizationMembersProvider);
    final currentRole = ref.watch(currentRoleProvider);
    final authUser = ref.watch(authStateProvider).value;
    final canInvite = RoleMatrix.canInviteOrRemoveMembers(currentRole);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team & Access Control',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (activeOrg != null)
              Text(
                'Organization: ${activeOrg.name}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
              ),
          ],
        ),
        actions: [
          if (canInvite)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const InviteMemberDialog(),
                  );
                },
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('Invite Member', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
        ],
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return const AppEmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No Members Found',
              description: 'This organization currently has no registered members.',
            );
          }

          // Count owners for Owner Retention rule
          final ownerCount = members.where((m) => m.role == AppRole.owner).length;

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final member = members[index];
              final isSelf = authUser != null && member.userId == authUser.uid;

              return _MemberCard(
                member: member,
                isSelf: isSelf,
                currentRole: currentRole,
                ownerCount: ownerCount,
                actorUid: authUser?.uid ?? '',
                actorEmail: authUser?.email ?? '',
              );
            },
          );
        },
        loading: () => const AppLoadingIndicator(message: 'Loading team directory...'),
        error: (err, _) => AppErrorWidget(
          error: err,
          onRetry: () => ref.refresh(organizationMembersProvider),
        ),
      ),
    );
  }
}

class _MemberCard extends ConsumerWidget {
  final MemberEntity member;
  final bool isSelf;
  final AppRole currentRole;
  final int ownerCount;
  final String actorUid;
  final String actorEmail;

  const _MemberCard({
    required this.member,
    required this.isSelf,
    required this.currentRole,
    required this.ownerCount,
    required this.actorUid,
    required this.actorEmail,
  });

  Future<void> _handleRoleChange(BuildContext context, WidgetRef ref, AppRole newRole) async {
    final activeOrgId = ref.read(activeOrganizationIdProvider);
    if (activeOrgId == null) return;

    // Owner Retention check
    if (member.role == AppRole.owner && newRole != AppRole.owner && ownerCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Owner Retention Rule: Organization must retain at least one active Owner.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final repo = ref.read(organizationRepositoryProvider);
      await repo.updateMemberRole(
        orgId: activeOrgId,
        targetUid: member.userId,
        targetEmail: member.email,
        oldRole: member.role,
        newRole: newRole,
        actorUid: actorUid,
        actorEmail: actorEmail,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated ${member.displayName} to ${newRole.value}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role update failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleRemoveMember(BuildContext context, WidgetRef ref) async {
    final activeOrgId = ref.read(activeOrganizationIdProvider);
    if (activeOrgId == null) return;

    // Owner Retention check
    if (member.role == AppRole.owner && ownerCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot remove the sole Owner. Transfer ownership first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        title: const Text('Confirm Member Removal'),
        content: Text(
          isSelf
              ? 'Are you sure you want to leave this organization?'
              : 'Are you sure you want to remove ${member.displayName} from this organization?',
        ),
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
            child: Text(isSelf ? 'Leave' : 'Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(organizationRepositoryProvider);
      await repo.removeMember(
        orgId: activeOrgId,
        targetUid: member.userId,
        targetEmail: member.email,
        actorUid: actorUid,
        actorEmail: actorEmail,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${member.displayName} from organization'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removal failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if current user can assign roles to this member
    final canModifyRole = !isSelf &&
        (currentRole == AppRole.owner ||
            (currentRole == AppRole.admin && member.role != AppRole.owner));

    final canRemove = RoleMatrix.canRemoveMember(
      actorRole: currentRole,
      targetRole: member.role,
      isSelf: isSelf,
    );

    // Filter available roles for dropdown
    final assignableRoles = currentRole == AppRole.owner
        ? AppRole.values
        : [AppRole.manager, AppRole.member, AppRole.viewer]; // Admin cannot promote to Owner!

    final profile = ref.watch(currentUserProfileProvider).value;
    final effectiveDisplayName = (isSelf && profile != null && profile.displayName.isNotEmpty)
        ? profile.displayName
        : (member.displayName.isNotEmpty ? member.displayName : member.email);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelf ? AppColors.primary.withOpacity(0.4) : AppColors.darkBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text(
              effectiveDisplayName.isNotEmpty
                  ? effectiveDisplayName.substring(0, 1).toUpperCase()
                  : 'M',
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        effectiveDisplayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  member.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Joined ${DateFormat.yMMMd().format(member.joinedAt)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMutedDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Role Badge or Role Dropdown
          if (canModifyRole)
            DropdownButton<AppRole>(
              value: member.role,
              dropdownColor: AppColors.darkSurface,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondaryDark),
              items: assignableRoles.map((r) {
                return DropdownMenuItem<AppRole>(
                  value: r,
                  child: RoleBadge(role: r, isSmall: true),
                );
              }).toList(),
              onChanged: (newRole) {
                if (newRole != null && newRole != member.role) {
                  _handleRoleChange(context, ref, newRole);
                }
              },
            )
          else
            RoleBadge(role: member.role),

          if (canRemove) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isSelf ? Icons.exit_to_app_rounded : Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.error.withOpacity(0.8),
              ),
              tooltip: isSelf ? 'Leave Organization' : 'Remove Member',
              onPressed: () => _handleRemoveMember(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}
