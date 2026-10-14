import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/organization_repository.dart';
import '../domain/invitation_entity.dart';
import '../domain/member_entity.dart';
import '../domain/organization_entity.dart';
import '../domain/role_matrix.dart';
import '../../auth/presentation/auth_providers.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository();
});

/// Currently selected active organization ID (Tenant context)
class ActiveOrganizationIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    final profile = ref.watch(currentUserProfileProvider).value;
    if (profile != null) {
      if (profile.defaultOrganizationId != null &&
          profile.organizationIds.contains(profile.defaultOrganizationId)) {
        return profile.defaultOrganizationId;
      }
      if (profile.organizationIds.isNotEmpty) {
        return profile.organizationIds.first;
      }
    }
    return null;
  }

  void setOrgId(String? orgId) {
    state = orgId;
  }
}

final activeOrganizationIdProvider =
    NotifierProvider<ActiveOrganizationIdNotifier, String?>(
        () => ActiveOrganizationIdNotifier());

/// Stream of all organizations the current user belongs to
final userOrganizationsProvider = StreamProvider<List<OrganizationEntity>>((ref) {
  final profile = ref.watch(currentUserProfileProvider).value;
  if (profile == null || profile.organizationIds.isEmpty) {
    return Stream.value([]);
  }
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.streamUserOrganizations(profile.organizationIds);
});

/// Stream of the active organization's details
final activeOrganizationProvider = StreamProvider<OrganizationEntity?>((ref) {
  final activeId = ref.watch(activeOrganizationIdProvider);
  if (activeId == null) return Stream.value(null);
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.streamOrganization(activeId);
});

/// Stream of all members in the active organization
final organizationMembersProvider = StreamProvider<List<MemberEntity>>((ref) {
  final activeId = ref.watch(activeOrganizationIdProvider);
  if (activeId == null) return Stream.value([]);
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.streamMembers(activeId);
});

/// Stream of current user's membership in the active organization
final currentMemberProvider = StreamProvider<MemberEntity?>((ref) {
  final activeId = ref.watch(activeOrganizationIdProvider);
  final authUser = ref.watch(authStateProvider).value;
  if (activeId == null || authUser == null) return Stream.value(null);

  final repo = ref.watch(organizationRepositoryProvider);
  return repo.streamCurrentMember(orgId: activeId, uid: authUser.uid);
});

/// Derived provider: Current user's role in active organization
final currentRoleProvider = Provider<AppRole>((ref) {
  final member = ref.watch(currentMemberProvider).value;
  return member?.role ?? AppRole.viewer;
});

/// Permission convenience providers
final canCreateTaskProvider = Provider<bool>((ref) {
  final role = ref.watch(currentRoleProvider);
  return RoleMatrix.canCreateTasks(role);
});

final canAssignTaskProvider = Provider<bool>((ref) {
  final role = ref.watch(currentRoleProvider);
  return RoleMatrix.canAssignTasks(role);
});

final canManageSettingsProvider = Provider<bool>((ref) {
  final role = ref.watch(currentRoleProvider);
  return RoleMatrix.canManageOrganizationSettings(role);
});

final canInviteMembersProvider = Provider<bool>((ref) {
  final role = ref.watch(currentRoleProvider);
  return RoleMatrix.canInviteOrRemoveMembers(role);
});

final canViewAuditLogsProvider = Provider<bool>((ref) {
  final role = ref.watch(currentRoleProvider);
  return RoleMatrix.canViewAuditLogs(role);
});

/// Stream of pending invitations for the currently authenticated user's email
final pendingInvitationsProvider = StreamProvider<List<InvitationEntity>>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null || authUser.email == null || authUser.email!.isEmpty) {
    return Stream.value([]);
  }
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.streamPendingInvitationsForEmail(authUser.email!);
});
