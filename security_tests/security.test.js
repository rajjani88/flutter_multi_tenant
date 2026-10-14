const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, addDoc, query, where, getDocs } = require('firebase/firestore');

const PROJECT_ID = 'multi-tenant-saas-test';

describe('Multi-Tenant SaaS Firestore Security Rules Test Suite', () => {
  let testEnv;

  beforeAll(async () => {
    const rulesPath = path.resolve(__dirname, '../firestore.rules');
    const rules = fs.readFileSync(rulesPath, 'utf8');

    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: rules,
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  afterAll(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();

    // Seed test organizations and memberships using privileged context
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      // Org 1: Acquired by Owner 1
      await setDoc(doc(db, 'organizations/org-1'), {
        id: 'org-1',
        name: 'Alpha Corp',
        ownerId: 'user-owner-1',
        createdAt: new Date(),
        updatedAt: new Date(),
        settings: { allowMemberInvites: true },
      });

      // Members in Org 1
      await setDoc(doc(db, 'organizations/org-1/members/user-owner-1'), {
        userId: 'user-owner-1',
        email: 'owner@alpha.com',
        role: 'Owner',
        joinedAt: new Date(),
      });
      await setDoc(doc(db, 'organizations/org-1/members/user-admin-1'), {
        userId: 'user-admin-1',
        email: 'admin@alpha.com',
        role: 'Admin',
        joinedAt: new Date(),
      });
      await setDoc(doc(db, 'organizations/org-1/members/user-manager-1'), {
        userId: 'user-manager-1',
        email: 'manager@alpha.com',
        role: 'Manager',
        joinedAt: new Date(),
      });
      await setDoc(doc(db, 'organizations/org-1/members/user-member-1'), {
        userId: 'user-member-1',
        email: 'member1@alpha.com',
        role: 'Member',
        joinedAt: new Date(),
      });
      await setDoc(doc(db, 'organizations/org-1/members/user-member-2'), {
        userId: 'user-member-2',
        email: 'member2@alpha.com',
        role: 'Member',
        joinedAt: new Date(),
      });
      await setDoc(doc(db, 'organizations/org-1/members/user-viewer-1'), {
        userId: 'user-viewer-1',
        email: 'viewer@alpha.com',
        role: 'Viewer',
        joinedAt: new Date(),
      });

      // Org 2: Competitor Org
      await setDoc(doc(db, 'organizations/org-2'), {
        id: 'org-2',
        name: 'Beta Ltd',
        ownerId: 'user-owner-2',
        createdAt: new Date(),
        updatedAt: new Date(),
        settings: {},
      });
      await setDoc(doc(db, 'organizations/org-2/members/user-owner-2'), {
        userId: 'user-owner-2',
        email: 'owner@beta.com',
        role: 'Owner',
        joinedAt: new Date(),
      });

      // Seed an existing task in Org 1 assigned to member-1
      await setDoc(doc(db, 'organizations/org-1/tasks/task-1'), {
        id: 'task-1',
        orgId: 'org-1',
        title: 'Initial Task',
        description: 'Assigned to member 1',
        status: 'To Do',
        priority: 'High',
        assigneeId: 'user-member-1',
        assigneeName: 'Member One',
        creatorId: 'user-owner-1',
        creatorName: 'Owner One',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      // Seed an existing audit log in Org 1
      await setDoc(doc(db, 'organizations/org-1/audit_logs/log-1'), {
        id: 'log-1',
        organizationId: 'org-1',
        actorId: 'user-owner-1',
        actorEmail: 'owner@alpha.com',
        action: 'org_created',
        targetId: 'org-1',
        targetType: 'organization',
        timestamp: new Date(),
        details: {},
      });
    });
  });

  // -------------------------------------------------------------
  // 1. DEFAULT DENY & TENANT ISOLATION
  // -------------------------------------------------------------
  describe('Default Deny & Tenant Isolation', () => {
    test('Unauthenticated user cannot read any organization data', async () => {
      const unauthDb = testEnv.unauthenticatedContext().firestore();
      await assertFails(getDoc(doc(unauthDb, 'organizations/org-1')));
    });

    test('Unauthenticated user cannot write any task', async () => {
      const unauthDb = testEnv.unauthenticatedContext().firestore();
      await assertFails(
        setDoc(doc(unauthDb, 'organizations/org-1/tasks/hack-task'), {
          title: 'Hacked Task',
        })
      );
    });

    test('Cross-tenant isolation: User in Org 1 CANNOT read Org 2 data', async () => {
      const org1UserDb = testEnv.authenticatedContext('user-member-1').firestore();
      await assertFails(getDoc(doc(org1UserDb, 'organizations/org-2')));
      await assertFails(getDoc(doc(org1UserDb, 'organizations/org-2/tasks/any-task')));
    });

    test('Cross-tenant isolation: User in Org 1 CANNOT write to Org 2', async () => {
      const org1UserDb = testEnv.authenticatedContext('user-owner-1').firestore();
      await assertFails(
        setDoc(doc(org1UserDb, 'organizations/org-2/tasks/malicious-task'), {
          id: 'malicious-task',
          orgId: 'org-2',
          title: 'Intrusion',
          creatorId: 'user-owner-1',
          status: 'To Do',
          priority: 'High',
        })
      );
    });
  });

  // -------------------------------------------------------------
  // 2. ROLE HIERARCHY & MEMBER MANAGEMENT
  // -------------------------------------------------------------
  describe('Role Hierarchy & Member Management', () => {
    test('Admin CANNOT promote anyone to Owner', async () => {
      const adminDb = testEnv.authenticatedContext('user-admin-1').firestore();
      await assertFails(
        updateDoc(doc(adminDb, 'organizations/org-1/members/user-member-1'), {
          role: 'Owner',
        })
      );
    });

    test('Admin CANNOT alter Owner membership role', async () => {
      const adminDb = testEnv.authenticatedContext('user-admin-1').firestore();
      await assertFails(
        updateDoc(doc(adminDb, 'organizations/org-1/members/user-owner-1'), {
          role: 'Viewer',
        })
      );
    });

    test('User CANNOT modify their own role (privilege self-escalation prevention)', async () => {
      const memberDb = testEnv.authenticatedContext('user-member-1').firestore();
      await assertFails(
        updateDoc(doc(memberDb, 'organizations/org-1/members/user-member-1'), {
          role: 'Admin',
        })
      );
    });

    test('Owner CAN update member role to Manager or Admin', async () => {
      const ownerDb = testEnv.authenticatedContext('user-owner-1').firestore();
      await assertSucceeds(
        updateDoc(doc(ownerDb, 'organizations/org-1/members/user-member-1'), {
          role: 'Manager',
        })
      );
    });

    test('Manager CANNOT invite new members', async () => {
      const managerDb = testEnv.authenticatedContext('user-manager-1').firestore();
      await assertFails(
        setDoc(doc(managerDb, 'organizations/org-1/members/new-user'), {
          userId: 'new-user',
          email: 'new@alpha.com',
          role: 'Member',
        })
      );
    });

    test('Admin CAN invite a new Member or Manager', async () => {
      const adminDb = testEnv.authenticatedContext('user-admin-1').firestore();
      await assertSucceeds(
        setDoc(doc(adminDb, 'organizations/org-1/members/new-user-2'), {
          userId: 'new-user-2',
          email: 'new2@alpha.com',
          role: 'Member',
        })
      );
    });
  });

  // -------------------------------------------------------------
  // 3. TASK SCOPE ENFORCEMENT & REAL-TIME RBAC
  // -------------------------------------------------------------
  describe('Task Scope & Permissions', () => {
    test('Viewer CAN read tasks, but CANNOT create, update, or delete', async () => {
      const viewerDb = testEnv.authenticatedContext('user-viewer-1').firestore();
      // Read allowed
      await assertSucceeds(getDoc(doc(viewerDb, 'organizations/org-1/tasks/task-1')));

      // Create denied
      await assertFails(
        setDoc(doc(viewerDb, 'organizations/org-1/tasks/viewer-task'), {
          id: 'viewer-task',
          orgId: 'org-1',
          title: 'Viewer Task',
          creatorId: 'user-viewer-1',
          status: 'To Do',
          priority: 'Low',
        })
      );

      // Update denied
      await assertFails(
        updateDoc(doc(viewerDb, 'organizations/org-1/tasks/task-1'), {
          status: 'Done',
        })
      );

      // Delete denied
      await assertFails(deleteDoc(doc(viewerDb, 'organizations/org-1/tasks/task-1')));
    });

    test('Member CAN update their OWN assigned task', async () => {
      const member1Db = testEnv.authenticatedContext('user-member-1').firestore();
      await assertSucceeds(
        updateDoc(doc(member1Db, 'organizations/org-1/tasks/task-1'), {
          status: 'In Progress',
        })
      );
    });

    test('Member CANNOT update another member assigned task', async () => {
      const member2Db = testEnv.authenticatedContext('user-member-2').firestore();
      await assertFails(
        updateDoc(doc(member2Db, 'organizations/org-1/tasks/task-1'), {
          status: 'Done',
        })
      );
    });

    test('Member CANNOT delete tasks', async () => {
      const member1Db = testEnv.authenticatedContext('user-member-1').firestore();
      await assertFails(deleteDoc(doc(member1Db, 'organizations/org-1/tasks/task-1')));
    });

    test('Manager CAN delete tasks', async () => {
      const managerDb = testEnv.authenticatedContext('user-manager-1').firestore();
      await assertSucceeds(deleteDoc(doc(managerDb, 'organizations/org-1/tasks/task-1')));
    });
  });

  // -------------------------------------------------------------
  // 4. AUDIT LOG IMMUTABILITY & ACCESS RESTRICTION
  // -------------------------------------------------------------
  describe('Audit Log Immutability & Access', () => {
    test('Member CANNOT view audit logs', async () => {
      const memberDb = testEnv.authenticatedContext('user-member-1').firestore();
      await assertFails(getDoc(doc(memberDb, 'organizations/org-1/audit_logs/log-1')));
    });

    test('Manager, Admin, and Owner CAN view audit logs', async () => {
      const managerDb = testEnv.authenticatedContext('user-manager-1').firestore();
      await assertSucceeds(getDoc(doc(managerDb, 'organizations/org-1/audit_logs/log-1')));

      const adminDb = testEnv.authenticatedContext('user-admin-1').firestore();
      await assertSucceeds(getDoc(doc(adminDb, 'organizations/org-1/audit_logs/log-1')));

      const ownerDb = testEnv.authenticatedContext('user-owner-1').firestore();
      await assertSucceeds(getDoc(doc(ownerDb, 'organizations/org-1/audit_logs/log-1')));
    });

    test('NO USER can modify or delete an audit log (Immutability)', async () => {
      const ownerDb = testEnv.authenticatedContext('user-owner-1').firestore();
      // Update denied even for Owner
      await assertFails(
        updateDoc(doc(ownerDb, 'organizations/org-1/audit_logs/log-1'), {
          action: 'tampered_action',
        })
      );
      // Delete denied even for Owner
      await assertFails(deleteDoc(doc(ownerDb, 'organizations/org-1/audit_logs/log-1')));
    });

    test('Invited user can query their invitations by email and accept', async () => {
      const ownerDb = testEnv.authenticatedContext('user-owner-1').firestore();
      // Owner creates an invitation
      await assertSucceeds(
        setDoc(doc(ownerDb, 'invitations/inv-1'), {
          id: 'inv-1',
          organizationId: 'org-1',
          organizationName: 'Alpha Corp',
          email: 'emp1@test.com',
          role: 'Manager',
          status: 'pending',
        })
      );

      // Invited user queries by email
      const empDb = testEnv.authenticatedContext('user-emp-1', { email: 'emp1@test.com' }).firestore();
      const q = query(collection(empDb, 'invitations'), where('email', '==', 'emp1@test.com'));
      await assertSucceeds(getDocs(q));

      // Another user with different email CANNOT query emp1 invitations
      const strangerDb = testEnv.authenticatedContext('user-stranger', { email: 'stranger@test.com' }).firestore();
      const strangerQ = query(collection(strangerDb, 'invitations'), where('email', '==', 'emp1@test.com'));
      await assertFails(getDocs(strangerQ));
    });
  });
});
