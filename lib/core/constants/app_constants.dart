class AppConstants {
  static const String appName = 'Nexus SaaS';
  static const String appTagline = 'Multi-Tenant Collaborative Workspace';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String organizationsCollection = 'organizations';
  static const String invitationsCollection = 'invitations';
  static const String membersSubcollection = 'members';
  static const String tasksSubcollection = 'tasks';
  static const String auditLogsSubcollection = 'audit_logs';

  // Roles
  static const String roleOwner = 'Owner';
  static const String roleAdmin = 'Admin';
  static const String roleManager = 'Manager';
  static const String roleMember = 'Member';
  static const String roleViewer = 'Viewer';

  static const List<String> allRoles = [
    roleOwner,
    roleAdmin,
    roleManager,
    roleMember,
    roleViewer,
  ];

  // Task Statuses
  static const String statusToDo = 'To Do';
  static const String statusInProgress = 'In Progress';
  static const String statusDone = 'Done';

  static const List<String> allStatuses = [
    statusToDo,
    statusInProgress,
    statusDone,
  ];

  // Task Priorities
  static const String priorityLow = 'Low';
  static const String priorityMedium = 'Medium';
  static const String priorityHigh = 'High';
  static const String priorityUrgent = 'Urgent';

  static const List<String> allPriorities = [
    priorityLow,
    priorityMedium,
    priorityHigh,
    priorityUrgent,
  ];
}
