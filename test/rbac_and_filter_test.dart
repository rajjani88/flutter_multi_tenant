import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_multi_tenant/features/organization/domain/role_matrix.dart';
import 'package:flutter_multi_tenant/features/tasks/domain/task_entity.dart';
import 'package:flutter_multi_tenant/features/tasks/domain/task_filter.dart';

void main() {
  group('RoleMatrix Domain Constraints & RBAC Action Matrix', () {
    test('Role permissions match exact specification matrix', () {
      // 1. View organization data: all roles
      for (final role in AppRole.values) {
        expect(RoleMatrix.canViewOrganizationData(role), isTrue);
      }

      // 2. Manage settings: Owner, Admin only
      expect(RoleMatrix.canManageOrganizationSettings(AppRole.owner), isTrue);
      expect(RoleMatrix.canManageOrganizationSettings(AppRole.admin), isTrue);
      expect(RoleMatrix.canManageOrganizationSettings(AppRole.manager), isFalse);
      expect(RoleMatrix.canManageOrganizationSettings(AppRole.member), isFalse);
      expect(RoleMatrix.canManageOrganizationSettings(AppRole.viewer), isFalse);

      // 3. Invite / remove members: Owner, Admin only
      expect(RoleMatrix.canInviteOrRemoveMembers(AppRole.owner), isTrue);
      expect(RoleMatrix.canInviteOrRemoveMembers(AppRole.admin), isTrue);
      expect(RoleMatrix.canInviteOrRemoveMembers(AppRole.manager), isFalse);
      expect(RoleMatrix.canInviteOrRemoveMembers(AppRole.member), isFalse);
      expect(RoleMatrix.canInviteOrRemoveMembers(AppRole.viewer), isFalse);

      // 4. Create tasks: Owner, Admin, Manager, Member (Viewer denied)
      expect(RoleMatrix.canCreateTasks(AppRole.owner), isTrue);
      expect(RoleMatrix.canCreateTasks(AppRole.admin), isTrue);
      expect(RoleMatrix.canCreateTasks(AppRole.manager), isTrue);
      expect(RoleMatrix.canCreateTasks(AppRole.member), isTrue);
      expect(RoleMatrix.canCreateTasks(AppRole.viewer), isFalse);

      // 5. Assign tasks: Owner, Admin, Manager
      expect(RoleMatrix.canAssignTasks(AppRole.owner), isTrue);
      expect(RoleMatrix.canAssignTasks(AppRole.admin), isTrue);
      expect(RoleMatrix.canAssignTasks(AppRole.manager), isTrue);
      expect(RoleMatrix.canAssignTasks(AppRole.member), isFalse);
      expect(RoleMatrix.canAssignTasks(AppRole.viewer), isFalse);

      // 6. Delete tasks: Owner, Admin, Manager
      expect(RoleMatrix.canDeleteTasks(AppRole.owner), isTrue);
      expect(RoleMatrix.canDeleteTasks(AppRole.admin), isTrue);
      expect(RoleMatrix.canDeleteTasks(AppRole.manager), isTrue);
      expect(RoleMatrix.canDeleteTasks(AppRole.member), isFalse);
      expect(RoleMatrix.canDeleteTasks(AppRole.viewer), isFalse);

      // 7. View audit logs: Owner, Admin, Manager
      expect(RoleMatrix.canViewAuditLogs(AppRole.owner), isTrue);
      expect(RoleMatrix.canViewAuditLogs(AppRole.admin), isTrue);
      expect(RoleMatrix.canViewAuditLogs(AppRole.manager), isTrue);
      expect(RoleMatrix.canViewAuditLogs(AppRole.member), isFalse);
      expect(RoleMatrix.canViewAuditLogs(AppRole.viewer), isFalse);
    });

    test('Member task update scope enforcement', () {
      const currentUserId = 'user-123';
      const otherUserId = 'user-456';

      // Member can update task assigned to them
      expect(
        RoleMatrix.canUpdateTask(
          role: AppRole.member,
          currentUserId: currentUserId,
          taskAssigneeId: currentUserId,
        ),
        isTrue,
      );

      // Member can update task created by them
      expect(
        RoleMatrix.canUpdateTask(
          role: AppRole.member,
          currentUserId: currentUserId,
          taskCreatorId: currentUserId,
        ),
        isTrue,
      );

      // Member CANNOT update task assigned to and created by someone else
      expect(
        RoleMatrix.canUpdateTask(
          role: AppRole.member,
          currentUserId: currentUserId,
          taskAssigneeId: otherUserId,
          taskCreatorId: otherUserId,
        ),
        isFalse,
      );

      // Viewer cannot update even if assigned to them
      expect(
        RoleMatrix.canUpdateTask(
          role: AppRole.viewer,
          currentUserId: currentUserId,
          taskAssigneeId: currentUserId,
        ),
        isFalse,
      );
    });

    test('Role hierarchy limits and self-escalation prevention', () {
      // Cannot modify own role
      expect(
        RoleMatrix.canAssignRole(
          actorRole: AppRole.admin,
          targetCurrentRole: AppRole.admin,
          desiredNewRole: AppRole.owner,
          isSelf: true,
        ),
        isFalse,
      );

      // Admin cannot promote anyone to Owner
      expect(
        RoleMatrix.canAssignRole(
          actorRole: AppRole.admin,
          targetCurrentRole: AppRole.member,
          desiredNewRole: AppRole.owner,
          isSelf: false,
        ),
        isFalse,
      );

      // Admin cannot alter Owner role
      expect(
        RoleMatrix.canAssignRole(
          actorRole: AppRole.admin,
          targetCurrentRole: AppRole.owner,
          desiredNewRole: AppRole.member,
          isSelf: false,
        ),
        isFalse,
      );

      // Owner can promote Member to Admin
      expect(
        RoleMatrix.canAssignRole(
          actorRole: AppRole.owner,
          targetCurrentRole: AppRole.member,
          desiredNewRole: AppRole.admin,
          isSelf: false,
        ),
        isTrue,
      );
    });
  });

  group('TaskFilter Tandem Multi-Attribute Filtering', () {
    final sampleTasks = [
      TaskEntity(
        id: '1',
        orgId: 'org-1',
        title: 'Fix Database Index',
        description: 'Postgres query tuning',
        status: 'To Do',
        priority: 'Urgent',
        assigneeId: 'user-a',
        assigneeName: 'Alice',
        creatorId: 'user-owner',
        creatorName: 'Owner',
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      ),
      TaskEntity(
        id: '2',
        orgId: 'org-1',
        title: 'Build UI Navigation',
        description: 'Implement GoRouter ShellRoute',
        status: 'In Progress',
        priority: 'High',
        assigneeId: 'user-b',
        assigneeName: 'Bob',
        creatorId: 'user-owner',
        creatorName: 'Owner',
        createdAt: DateTime(2026, 10, 5),
        updatedAt: DateTime(2026, 10, 5),
      ),
      TaskEntity(
        id: '3',
        orgId: 'org-1',
        title: 'Write Security Tests',
        description: 'Jest and emulator suite',
        status: 'Done',
        priority: 'High',
        assigneeId: 'user-a',
        assigneeName: 'Alice',
        creatorId: 'user-owner',
        creatorName: 'Owner',
        createdAt: DateTime(2026, 10, 10),
        updatedAt: DateTime(2026, 10, 10),
      ),
    ];

    test('Filters in tandem: status + priority', () {
      const filter = TaskFilter(status: 'Done', priority: 'High');
      final result = filter.apply(sampleTasks);
      expect(result.length, 1);
      expect(result.first.id, '3');
    });

    test('Filters in tandem: status + assignee', () {
      const filter = TaskFilter(status: 'To Do', assigneeId: 'user-a');
      final result = filter.apply(sampleTasks);
      expect(result.length, 1);
      expect(result.first.title, 'Fix Database Index');
    });

    test('Filters in tandem: priority + date range', () {
      final filter = TaskFilter(
        priority: 'High',
        startDate: DateTime(2026, 10, 4),
        endDate: DateTime(2026, 10, 6),
      );
      final result = filter.apply(sampleTasks);
      expect(result.length, 1);
      expect(result.first.id, '2');
    });

    test('Search query matches case-insensitively', () {
      const filter = TaskFilter(searchQuery: 'gorouter');
      final result = filter.apply(sampleTasks);
      expect(result.length, 1);
      expect(result.first.id, '2');
    });
  });
}
