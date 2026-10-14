# Nexus SaaS: Architecture Summary Document

This document provides a comprehensive overview of the technical architecture, security model, and design decisions for the **Multi-Tenant SaaS Application**.

---

## 1. Architectural Pattern: Clean Architecture

The application strictly adheres to Clean Architecture principles, ensuring complete decoupling between presentation, business logic, and data infrastructure:

```
lib/
├── core/                                # Cross-cutting concerns & foundational primitives
│   ├── constants/app_constants.dart     # Single source of truth for collections, roles, statuses
│   ├── network/                         # Connectivity monitoring & failure simulation
│   ├── theme/                           # Modern design system, colors, typography
│   └── widgets/                         # Reusable UI states (empty, loading, error, badges)
├── features/
│   ├── auth/                            # User profile and Firebase Auth integration
│   │   ├── domain/user_entity.dart
│   │   ├── data/auth_repository.dart
│   │   └── presentation/                # Auth screens & Riverpod auth providers
│   ├── organization/                    # Multi-tenant management & 5-role RBAC
│   │   ├── domain/                      # RoleMatrix, MemberEntity, OrganizationEntity
│   │   ├── data/organization_repository.dart
│   │   └── presentation/                # Switcher, Members directory, Settings
│   ├── tasks/                           # Real-time task management & tandem filtering
│   │   ├── domain/                      # TaskEntity, TaskFilter
│   │   ├── data/task_repository.dart
│   │   └── presentation/                # Task board, TaskForm dialog, filter bar
│   └── audit/                           # Immutable audit trail
│       ├── domain/audit_log_entity.dart
│       ├── data/audit_repository.dart
│       └── presentation/audit_logs_screen.dart
└── routes/app_router.dart               # Declarative routing with GoRouter
```

---

## 2. State Management Justification: Riverpod 3.x

**Riverpod** was chosen over Provider and BLoC for the following technical reasons:
1. **Compile-Time Safety & Decoupled Context**: Unlike Provider, Riverpod does not depend on `BuildContext` to read or mutate state, eliminating runtime `ProviderNotFoundException` bugs and allowing repository calls and streams outside the widget tree.
2. **First-Class Reactive Streams**: Multi-tenancy relies on active Firestore streams (`StreamProvider`). When a user switches organizations, Riverpod automatically cancels stale tenant listeners and binds to the new organization without memory leaks or race conditions.
3. **Derived State & Auto-Disposal**: Filtering tasks by multiple attributes in tandem (Status, Priority, Assignee, Date Range) is represented as a pure synchronous derivation (`filteredTasksProvider`), updating at 60 FPS without redundant network calls.

---

## 3. Multi-Tenant Data Isolation Strategy

Data isolation is guaranteed through **Hierarchical Subcollection Partitioning**:

```
/users/{userId}                              <-- Global user profiles (strictly private to owner)
/organizations/{orgId}                       <-- Organization metadata & settings
/organizations/{orgId}/members/{userId}      <-- Tenant membership & assigned role
/organizations/{orgId}/tasks/{taskId}        <-- Task items partitioned by tenant
/organizations/{orgId}/audit_logs/{logId}    <-- Immutable audit trail
```

### Why Subcollections over Flat Collections?
1. **Physical Boundary**: Querying `/organizations/{orgId}/tasks` makes cross-tenant data leaks impossible by design; queries cannot accidentally span tenants without collection-group queries.
2. **Atomic Organization Membership Verification**: Security rules verify membership by checking document existence:
   ```javascript
   exists(/databases/$(database)/documents/organizations/$(orgId)/members/$(request.auth.uid))
   ```
3. **No Unauthenticated Leaks**: Without membership in `members/{userId}`, all queries against an organization's subcollections are denied at the Firestore engine level.

---

## 4. Role-Based Access Control (RBAC) Matrix

The system implements 5 distinct roles matching the technical brief:

| Action | Owner | Admin | Manager | Member | Viewer |
|---|:---:|:---:|:---:|:---:|:---:|
| **View organization data** | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Manage organization settings** | ✓ | ✓ | — | — | — |
| **Invite / remove members** | ✓ | ✓ | — | — | — |
| **Change member roles** | ✓ | Limited* | — | — | — |
| **Create tasks** | ✓ | ✓ | ✓ | ✓ | — |
| **Assign tasks** | ✓ | ✓ | ✓ | — | — |
| **Update assigned tasks** | ✓ | ✓ | ✓ | Own Only** | — |
| **Delete tasks** | ✓ | ✓ | ✓ | — | — |
| **View audit logs** | ✓ | ✓ | ✓ | — | — |

*\* Limited: Admins cannot promote anyone to Owner, nor alter the role of an Owner.*  
*\*\* Own Only: Members can only update tasks assigned to them or created by them, and cannot reassign tasks to others.*

---

## 5. Security Rules & Integrity Constraints

All constraints are enforced at the backend level in `firestore.rules`:
1. **Global Default Deny**: Every path starts with `allow read, write: if false;`.
2. **Owner Retention Rule**: Organizations must retain at least one active Owner. Attempting to remove or demote the last Owner is blocked.
3. **Self-Escalation Prevention**: A user cannot update their own membership document to elevate their role.
4. **Audit Log Immutability**: Rules strictly enforce `allow update, delete: if false;` on `/audit_logs/{logId}`. Once recorded, entries cannot be tampered with.

---

## 6. Resilience & Failure Handling

1. **Network Degradation Simulator**: Built-in toggle in Organization Settings adds simulated +2000ms latency to test loading spinners, debouncing, and optimistic state handling.
2. **Offline Persistence**: Firestore offline persistence is enabled (`cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED`).
3. **Permission-Denied Handling**: The UI catches `permission-denied` errors and displays informative, human-readable notices via `AppErrorWidget` instead of cryptic error dumps.
