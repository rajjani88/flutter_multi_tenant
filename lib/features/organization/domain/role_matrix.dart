import '../../../core/constants/app_constants.dart';

enum AppRole {
  owner(AppConstants.roleOwner),
  admin(AppConstants.roleAdmin),
  manager(AppConstants.roleManager),
  member(AppConstants.roleMember),
  viewer(AppConstants.roleViewer);

  final String value;
  const AppRole(this.value);

  static AppRole fromString(String? roleStr) {
    switch (roleStr) {
      case AppConstants.roleOwner:
        return AppRole.owner;
      case AppConstants.roleAdmin:
        return AppRole.admin;
      case AppConstants.roleManager:
        return AppRole.manager;
      case AppConstants.roleMember:
        return AppRole.member;
      case AppConstants.roleViewer:
      default:
        return AppRole.viewer;
    }
  }
}

/// Strict enforcement of the Role Action Matrix from the specification
class RoleMatrix {
  /// View organization data: Owner, Admin, Manager, Member, Viewer
  static bool canViewOrganizationData(AppRole role) => true;

  /// Manage organization settings: Owner, Admin
  static bool canManageOrganizationSettings(AppRole role) {
    return role == AppRole.owner || role == AppRole.admin;
  }

  /// Invite / remove members: Owner, Admin
  static bool canInviteOrRemoveMembers(AppRole role) {
    return role == AppRole.owner || role == AppRole.admin;
  }

  /// Change member roles: Owner (Full), Admin (Limited)
  static bool canChangeMemberRoles(AppRole role) {
    return role == AppRole.owner || role == AppRole.admin;
  }

  /// Check if actor can assign a specific target role to another member
  /// Admin cannot promote to Owner.
  static bool canAssignRole({
    required AppRole actorRole,
    required AppRole targetCurrentRole,
    required AppRole desiredNewRole,
    required bool isSelf,
  }) {
    // A user cannot change their own role (self-escalation / de-escalation integrity)
    if (isSelf) return false;

    // Owner can change any role to any role
    if (actorRole == AppRole.owner) {
      return true;
    }

    // Admin has limited capability:
    // - Cannot modify an Owner
    // - Cannot assign the Owner role
    if (actorRole == AppRole.admin) {
      if (targetCurrentRole == AppRole.owner) return false;
      if (desiredNewRole == AppRole.owner) return false;
      return true;
    }

    // Manager, Member, Viewer cannot change roles
    return false;
  }

  /// Check if actor can remove a member
  /// Admin cannot remove Owner. Member can leave themselves if not Owner.
  static bool canRemoveMember({
    required AppRole actorRole,
    required AppRole targetRole,
    required bool isSelf,
  }) {
    if (isSelf) {
      // Non-owner can leave organization
      return targetRole != AppRole.owner;
    }

    if (actorRole == AppRole.owner) return true;
    if (actorRole == AppRole.admin) {
      return targetRole != AppRole.owner;
    }
    return false;
  }

  /// Create tasks: Owner, Admin, Manager, Member
  static bool canCreateTasks(AppRole role) {
    return role != AppRole.viewer;
  }

  /// Assign tasks: Owner, Admin, Manager
  static bool canAssignTasks(AppRole role) {
    return role == AppRole.owner || role == AppRole.admin || role == AppRole.manager;
  }

  /// Update assigned tasks:
  /// - Owner, Admin, Manager can update any task
  /// - Member can ONLY update their OWN assigned or created task
  /// - Viewer has read-only access
  static bool canUpdateTask({
    required AppRole role,
    required String currentUserId,
    String? taskAssigneeId,
    String? taskCreatorId,
  }) {
    if (role == AppRole.viewer) return false;
    if (role == AppRole.owner || role == AppRole.admin || role == AppRole.manager) {
      return true;
    }
    if (role == AppRole.member) {
      return (taskAssigneeId != null && taskAssigneeId == currentUserId) ||
          (taskCreatorId != null && taskCreatorId == currentUserId);
    }
    return false;
  }

  /// Delete tasks: Owner, Admin, Manager
  static bool canDeleteTasks(AppRole role) {
    return role == AppRole.owner || role == AppRole.admin || role == AppRole.manager;
  }

  /// View audit logs: Owner, Admin, Manager
  static bool canViewAuditLogs(AppRole role) {
    return role == AppRole.owner || role == AppRole.admin || role == AppRole.manager;
  }
}
