import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/user_entity.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Stream current user's profile from Firestore
  Stream<UserEntity?> streamUserProfile(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return null;
          }
          return UserEntity.fromFirestore(doc);
        });
  }

  Future<void> _ensureProfileExists(String uid) async {
    final user = _auth.currentUser;
    if (user != null && user.uid == uid) {
      final docRef = _firestore.collection(AppConstants.usersCollection).doc(uid);
      final snap = await docRef.get();
      if (!snap.exists) {
        final fallbackName = (user.displayName != null && user.displayName!.isNotEmpty)
            ? user.displayName!
            : (user.email?.split('@').first ?? 'User');
        await docRef.set({
          'uid': uid,
          'email': user.email ?? '',
          'displayName': fallbackName,
          'organizationIds': <String>[],
          'createdAt': Timestamp.now(),
        });
      }
    }
  }

  /// Sign In with Email & Password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user != null) {
      await _ensureProfileExists(user.uid);
    }
    return cred;
  }

  /// Sign Up with Email, Password & Display Name
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cleanEmail = email.trim();
    final cleanName = displayName.trim();

    final cred = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = cred.user;
    if (user != null) {
      final finalName = cleanName.isNotEmpty ? cleanName : cleanEmail.split('@').first;
      await user.updateDisplayName(finalName);
      await user.reload();

      final userEntity = UserEntity(
        uid: user.uid,
        email: cleanEmail,
        displayName: finalName,
        organizationIds: const [],
        createdAt: DateTime.now(),
      );

      // Save user profile in Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userEntity.toFirestore());
    }

    return cred;
  }

  /// Update user's display name across Auth, Firestore profile, and active membership
  Future<void> updateDisplayName({
    required String uid,
    required String newDisplayName,
    String? activeOrgId,
  }) async {
    final cleanName = newDisplayName.trim();
    if (cleanName.isEmpty) return;

    final user = _auth.currentUser;
    if (user != null && user.uid == uid) {
      await user.updateDisplayName(cleanName);
      await user.reload();
    }

    final batch = _firestore.batch();
    final userRef = _firestore.collection(AppConstants.usersCollection).doc(uid);
    batch.update(userRef, {'displayName': cleanName});

    if (activeOrgId != null && activeOrgId.isNotEmpty) {
      final memberRef = _firestore
          .collection(AppConstants.organizationsCollection)
          .doc(activeOrgId)
          .collection(AppConstants.membersSubcollection)
          .doc(uid);
      batch.update(memberRef, {'displayName': cleanName});
    }

    await batch.commit();
  }

  /// Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Update user default organization
  Future<void> setDefaultOrganization(String uid, String orgId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'defaultOrganizationId': orgId});
  }

  /// Add organization to user's list
  Future<void> addOrganizationToUser(String uid, String orgId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'organizationIds': FieldValue.arrayUnion([orgId]),
      'defaultOrganizationId': orgId,
    });
  }
}
