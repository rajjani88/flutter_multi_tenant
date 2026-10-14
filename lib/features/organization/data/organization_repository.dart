import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/invitation_entity.dart';
import '../domain/member_entity.dart';
import '../domain/organization_entity.dart';
import '../domain/role_matrix.dart';

class OrganizationRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  OrganizationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream a single organization
  Stream<OrganizationEntity?> streamOrganization(String orgId) {
    if (orgId.isEmpty) return Stream.value(null);
    return _firestore
        .collection(AppConstants.organizationsCollection)
        .doc(orgId)
        .snapshots()
        .map((doc) => doc.exists ? OrganizationEntity.fromFirestore(doc) : null);
  }

  /// Stream all members of an organization
  Stream<List<MemberEntity>> streamMembers(String orgId) {
    if (orgId.isEmpty) return Stream.value([]);
    return _firestore
        .collection(AppConstants.organizationsCollection)
        .doc(orgId)
        .collection(AppConstants.membersSubcollection)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MemberEntity.fromFirestore(d)).toList());
  }

  /// Stream current user's membership doc in the active organization
  Stream<MemberEntity?> streamCurrentMember({
    required String orgId,
    required String uid,
  }) {
    if (orgId.isEmpty || uid.isEmpty) return Stream.value(null);
    return _firestore
        .collection(AppConstants.organizationsCollection)
        .doc(orgId)
        .collection(AppConstants.membersSubcollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? MemberEntity.fromFirestore(doc) : null);
  }

  /// Stream multiple organizations for a user
  Stream<List<OrganizationEntity>> streamUserOrganizations(List<String> orgIds) {
    if (orgIds.isEmpty) return Stream.value([]);
    // Firestore whereIn supports up to 30 items
    final safeIds = orgIds.take(30).toList();
    return _firestore
        .collection(AppConstants.organizationsCollection)
        .where(FieldPath.documentId, whereIn: safeIds)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OrganizationEntity.fromFirestore(d)).toList());
  }

  /// Create a brand new organization with atomic transaction/batch
  Future<String> createOrganization({
    required String name,
    required String ownerUid,
    required String ownerEmail,
    required String ownerDisplayName,
  }) async {
    final orgId = _uuid.v4();
    final now = DateTime.now();
    final batch = _firestore.batch();

    // 1. Organization doc
    final orgRef = _firestore.collection(AppConstants.organizationsCollection).doc(orgId);
    final orgEntity = OrganizationEntity(
      id: orgId,
      name: name.trim(),
      ownerId: ownerUid,
      createdAt: now,
      updatedAt: now,
      settings: const {
        'allowMemberInvites': true,
        'description': 'Workspace created on Nexus SaaS',
      },
    );
    batch.set(orgRef, orgEntity.toFirestore());

    // 2. Initial Member doc (Owner role)
    final memberRef = orgRef.collection(AppConstants.membersSubcollection).doc(ownerUid);
    final memberEntity = MemberEntity(
      userId: ownerUid,
      email: ownerEmail,
      displayName: ownerDisplayName.isNotEmpty ? ownerDisplayName : ownerEmail,
      role: AppRole.owner,
      joinedAt: now,
    );
    batch.set(memberRef, memberEntity.toFirestore());

    // 3. Initial Audit log
    final logId = _uuid.v4();
    final auditRef = orgRef.collection(AppConstants.auditLogsSubcollection).doc(logId);
    batch.set(auditRef, {
      'id': logId,
      'organizationId': orgId,
      'actorId': ownerUid,
      'actorEmail': ownerEmail,
      'action': 'org_created',
      'targetId': orgId,
      'targetType': 'organization',
      'timestamp': Timestamp.fromDate(now),
      'details': {'name': name.trim()},
    });

    // 4. Update user's organization index (merge organizationId without overwriting displayName)
    final userRef = _firestore.collection(AppConstants.usersCollection).doc(ownerUid);
    batch.set(userRef, {
      'uid': ownerUid,
      'email': ownerEmail,
      'organizationIds': FieldValue.arrayUnion([orgId]),
      'defaultOrganizationId': orgId,
    }, SetOptions(merge: true));

    await batch.commit();
    return orgId;
  }

  /// Invite/Add a member to the organization
  Future<void> addMember({
    required String orgId,
    String? orgName,
    required String targetUid,
    required String targetEmail,
    required String targetDisplayName,
    required AppRole role,
    required String actorUid,
    required String actorEmail,
  }) async {
    final now = DateTime.now();
    final cleanEmail = targetEmail.trim().toLowerCase();
    final batch = _firestore.batch();

    final orgRef = _firestore.collection(AppConstants.organizationsCollection).doc(orgId);
    final memberRef = orgRef.collection(AppConstants.membersSubcollection).doc(targetUid);

    // 1. Placeholder Member doc (for tenant member roster)
    final memberEntity = MemberEntity(
      userId: targetUid,
      email: cleanEmail,
      displayName: targetDisplayName.trim().isNotEmpty ? targetDisplayName.trim() : cleanEmail,
      role: role,
      joinedAt: now,
      invitedBy: actorUid,
    );
    batch.set(memberRef, memberEntity.toFirestore());

    // 2. Global Invitation doc (for discovery by invited user's email)
    final inviteId = _uuid.v4();
    final inviteRef = _firestore.collection(AppConstants.invitationsCollection).doc(inviteId);
    final inviteEntity = InvitationEntity(
      id: inviteId,
      organizationId: orgId,
      organizationName: orgName?.trim().isNotEmpty == true ? orgName!.trim() : 'Workspace',
      email: cleanEmail,
      role: role,
      invitedBy: actorUid,
      invitedByEmail: actorEmail,
      status: 'pending',
      createdAt: now,
    );
    batch.set(inviteRef, inviteEntity.toFirestore());

    // 3. Audit log
    final logId = _uuid.v4();
    final auditRef = orgRef.collection(AppConstants.auditLogsSubcollection).doc(logId);
    batch.set(auditRef, {
      'id': logId,
      'organizationId': orgId,
      'actorId': actorUid,
      'actorEmail': actorEmail,
      'action': 'member_invited',
      'targetId': targetUid,
      'targetType': 'member',
      'timestamp': Timestamp.fromDate(now),
      'details': {
        'email': cleanEmail,
        'assignedRole': role.value,
        'invitationId': inviteId,
      },
    });

    await batch.commit();
  }

  /// Stream pending workspace invitations for a given email
  Stream<List<InvitationEntity>> streamPendingInvitationsForEmail(String email) {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return Stream.value([]);

    return _firestore
        .collection(AppConstants.invitationsCollection)
        .where('email', isEqualTo: cleanEmail)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((invitesSnap) async {
      final invitations = invitesSnap.docs
          .map((d) => InvitationEntity.fromFirestore(d))
          .toList();

      if (invitations.isNotEmpty) {
        return invitations;
      }

      // Fallback check for legacy / placeholder member docs created in collectionGroup
      try {
        final membersSnap = await _firestore
            .collectionGroup(AppConstants.membersSubcollection)
            .where('email', isEqualTo: cleanEmail)
            .get();

        for (final doc in membersSnap.docs) {
          final parentOrgRef = doc.reference.parent.parent;
          if (parentOrgRef != null) {
            final orgId = parentOrgRef.id;
            final alreadyListed = invitations.any((i) => i.organizationId == orgId);
            if (!alreadyListed && doc.id.startsWith('user_')) {
              final data = doc.data();
              // Try to fetch org name
              String orgName = 'Workspace';
              try {
                final orgDoc = await parentOrgRef.get();
                if (orgDoc.exists) {
                  orgName = orgDoc.data()?['name'] as String? ?? 'Workspace';
                }
              } catch (_) {}

              invitations.add(
                InvitationEntity(
                  id: doc.id,
                  organizationId: orgId,
                  organizationName: orgName,
                  email: cleanEmail,
                  role: AppRole.fromString(data['role'] as String?),
                  invitedBy: data['invitedBy'] as String? ?? '',
                  invitedByEmail: 'Workspace Admin',
                  status: 'pending',
                  createdAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                ),
              );
            }
          }
        }
      } catch (_) {}

      return invitations;
    });
  }

  /// Accept a workspace invitation
  Future<void> acceptInvitation({
    required InvitationEntity invitation,
    required String userUid,
    required String userEmail,
    required String userDisplayName,
  }) async {
    final now = DateTime.now();
    final batch = _firestore.batch();
    final orgId = invitation.organizationId;
    final cleanEmail = userEmail.trim().toLowerCase();
    final orgRef = _firestore.collection(AppConstants.organizationsCollection).doc(orgId);

    // 1. Create active member doc under user's actual UID
    final memberRef = orgRef.collection(AppConstants.membersSubcollection).doc(userUid);
    final memberEntity = MemberEntity(
      userId: userUid,
      email: cleanEmail,
      displayName: userDisplayName.trim().isNotEmpty ? userDisplayName.trim() : cleanEmail,
      role: invitation.role,
      joinedAt: now,
      invitedBy: invitation.invitedBy,
    );
    batch.set(memberRef, memberEntity.toFirestore());

    // 2. Remove placeholder member doc if one was used
    final placeholderId = 'user_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    final placeholderRef = orgRef.collection(AppConstants.membersSubcollection).doc(placeholderId);
    batch.delete(placeholderRef);

    // 3. Update global invitation record if it was an invitation document
    if (!invitation.id.startsWith('user_')) {
      final inviteRef = _firestore.collection(AppConstants.invitationsCollection).doc(invitation.id);
      batch.update(inviteRef, {
        'status': 'accepted',
        'acceptedByUid': userUid,
        'acceptedAt': Timestamp.fromDate(now),
      });
    }

    // 4. Audit log
    final logId = _uuid.v4();
    final auditRef = orgRef.collection(AppConstants.auditLogsSubcollection).doc(logId);
    batch.set(auditRef, {
      'id': logId,
      'organizationId': orgId,
      'actorId': userUid,
      'actorEmail': cleanEmail,
      'action': 'invitation_accepted',
      'targetId': userUid,
      'targetType': 'member',
      'timestamp': Timestamp.fromDate(now),
      'details': {
        'role': invitation.role.value,
        'organizationName': invitation.organizationName,
      },
    });

    // 5. Update user's profile with organization ID
    final userRef = _firestore.collection(AppConstants.usersCollection).doc(userUid);
    batch.set(userRef, {
      'organizationIds': FieldValue.arrayUnion([orgId]),
      'defaultOrganizationId': orgId,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Decline a workspace invitation
  Future<void> declineInvitation({
    required InvitationEntity invitation,
    required String userUid,
  }) async {
    final batch = _firestore.batch();
    if (!invitation.id.startsWith('user_')) {
      final inviteRef = _firestore.collection(AppConstants.invitationsCollection).doc(invitation.id);
      batch.update(inviteRef, {'status': 'declined'});
    }
    final cleanEmail = invitation.email.trim().toLowerCase();
    final placeholderId = 'user_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    final orgRef = _firestore.collection(AppConstants.organizationsCollection).doc(invitation.organizationId);
    final placeholderRef = orgRef.collection(AppConstants.membersSubcollection).doc(placeholderId);
    batch.delete(placeholderRef);

    await batch.commit();
  }

  /// Update a member's role
  Future<void> updateMemberRole({
    required String orgId,
    required String targetUid,
    required String targetEmail,
    required AppRole oldRole,
    required AppRole newRole,
    required String actorUid,
    required String actorEmail,
  }) async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    final orgRef = _firestore.collection(AppConstants.organizationsCollection).doc(orgId);
    final memberRef = orgRef.collection(AppConstants.membersSubcollection).doc(targetUid);

    batch.update(memberRef, {'role': newRole.value});

    // Audit log
    final logId = _uuid.v4();
    final auditRef = orgRef.collection(AppConstants.auditLogsSubcollection).doc(logId);
    batch.set(auditRef, {
      'id': logId,
      'organizationId': orgId,
      'actorId': actorUid,
      'actorEmail': actorEmail,
      'action': 'role_changed',
      'targetId': targetUid,
      'targetType': 'member',
      'timestamp': Timestamp.fromDate(now),
      'details': {
        'memberEmail': targetEmail,
        'previousRole': oldRole.value,
        'newRole': newRole.value,
      },
    });

    await batch.commit();
  }

  /// Remove a member from the organization
  Future<void> removeMember({
    required String orgId,
    required String targetUid,
    required String targetEmail,
    required String actorUid,
    required String actorEmail,
  }) async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    final orgRef = _firestore.collection(AppConstants.organizationsCollection).doc(orgId);
    final memberRef = orgRef.collection(AppConstants.membersSubcollection).doc(targetUid);

    batch.delete(memberRef);

    // Audit log
    final logId = _uuid.v4();
    final auditRef = orgRef.collection(AppConstants.auditLogsSubcollection).doc(logId);
    batch.set(auditRef, {
      'id': logId,
      'organizationId': orgId,
      'actorId': actorUid,
      'actorEmail': actorEmail,
      'action': 'member_removed',
      'targetId': targetUid,
      'targetType': 'member',
      'timestamp': Timestamp.fromDate(now),
      'details': {'memberEmail': targetEmail},
    });

    await batch.commit();
  }

  /// Update organization settings
  Future<void> updateSettings({
    required String orgId,
    required String newName,
    required Map<String, dynamic> settings,
    required String actorUid,
    required String actorEmail,
  }) async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    final orgRef = _firestore.collection(AppConstants.organizationsCollection).doc(orgId);
    batch.update(orgRef, {
      'name': newName.trim(),
      'settings': settings,
      'updatedAt': Timestamp.fromDate(now),
    });

    // Audit log
    final logId = _uuid.v4();
    final auditRef = orgRef.collection(AppConstants.auditLogsSubcollection).doc(logId);
    batch.set(auditRef, {
      'id': logId,
      'organizationId': orgId,
      'actorId': actorUid,
      'actorEmail': actorEmail,
      'action': 'settings_updated',
      'targetId': orgId,
      'targetType': 'organization',
      'timestamp': Timestamp.fromDate(now),
      'details': {'name': newName.trim(), 'settings': settings},
    });

    await batch.commit();
  }
}
