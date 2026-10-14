# Nexus SaaS: Multi-Tenant Collaborative Workspace

> A mini production-style multi-tenant SaaS application built with **Flutter 3**, **Riverpod 3**, and **Firebase (Auth & Cloud Firestore)**.

---

## 🌟 Key Features

1. **Multi-Tenancy & Context Switching**:
   - Organization creation with automatic Owner designation.
   - Users can belong to multiple organizations and switch active tenant context seamlessly.
   - Stream rebinding ensures zero cross-tenant data bleed.

2. **5-Role Access Control Model (RBAC)**:
   - Roles: `Owner`, `Admin`, `Manager`, `Member`, `Viewer`.
   - Backend-enforced via **Cloud Firestore Security Rules** starting from a global default-deny stance.
   - Strict role hierarchy limits: Admins cannot promote to Owner or alter Owner membership; Members can only update self-assigned/created tasks; Viewers are read-only.
   - Owner retention guarantee: organizations must retain at least one active Owner.

3. **Real-Time Task Management & Tandem Filtering**:
   - Real-time reactive sync across all connected clients in the active tenant.
   - Multi-attribute filtering in tandem: **Status**, **Priority**, **Assignee**, **Date Range**, and **Search**.

4. **Tamper-Proof Audit Logging**:
   - Every sensitive event (member invited, role changed, member removed, task created/updated/deleted, settings updated) is logged with actor metadata and parameter diffs.
   - Rules strictly forbid updates or deletions of audit entries (`allow update, delete: if false;`).

5. **Failure & Resilience Handling**:
   - In-app **Resilience & Degraded Network Simulator** (+2000ms latency toggle).
   - Graceful handling of network loss with offline persistence.
   - Custom `AppErrorWidget` handling `permission-denied` and other edge cases with friendly feedback.

---

## 🚀 Getting Started & Local Development

### 1. Prerequisites
- **Flutter SDK**: 3.24+ (Dart 3.5+)
- **Node.js**: v18+ & **Firebase CLI** (`npm install -g firebase-tools`)
- **Java**: JRE 11+ (required by Firebase Local Emulator)

### 2. Install Dependencies
```bash
# Install Flutter dependencies
flutter pub get

# Install security test runner dependencies
cd security_tests
npm install
cd ..
```

### 3. Run Automated Security Rules Test Suite
To verify tenant isolation, role hierarchy limits, direct attack vector rejections, and audit log immutability against the Firestore Emulator:
```bash
./scripts/test_security_rules.sh
```
*Expected Result:* 19 passed tests in Jest.

### 4. Run Flutter Unit Tests
To verify RBAC domain logic, hierarchy constraints, and tandem task filtering:
```bash
flutter test
```

### 5. Launch Firebase Local Emulators
```bash
firebase emulators:start
```
- Auth Emulator: `localhost:9099`
- Firestore Emulator: `localhost:8080`
- Emulator UI: `localhost:4000`

### 6. Run the Flutter Application
```bash
# Run on macOS / Chrome / iOS / Android
flutter run -d chrome
# or
flutter run -d macos
```

### 7. Deploy to Firebase Hosting (Production)
To compile the web release bundle and deploy to global CDN with single-page app rewrites:
```bash
./scripts/deploy_hosting.sh
```
Or manually:
```bash
flutter build web --release
firebase deploy --only hosting,firestore
```
- **Live Hosting URL**: `https://test-multitenant-6397f.web.app`

---

## 📂 Project Structure

- `lib/core/`: Application constants, dark theme, colors, connectivity monitoring, and state widgets (`RoleBadge`, `StatusBadge`, `PriorityBadge`, `AppErrorWidget`, `AppEmptyState`, `DegradedNetworkBanner`).
- `lib/features/auth/`: Firebase Auth repository, user profiles, login, and registration screens.
- `lib/features/organization/`: Tenant lifecycle, role matrix domain logic, member directory, invitations, and settings.
- `lib/features/tasks/`: Real-time task board, tandem filter bar, task form dialog with role gating, and task card with quick status toggles.
- `lib/features/audit/`: Audit repository, audit stream provider, and expandable audit history timeline.
- `firestore.rules`: Global default-deny security rules enforcing multi-tenancy and RBAC.
- `security_tests/`: Jest automated tests simulating attacks directly against the Firestore emulator.
- `ARCHITECTURE.md`: Detailed architecture and state management justification.
- `AI_DISCLOSURE.md`: AI tool usage disclosure and verification documentation.
