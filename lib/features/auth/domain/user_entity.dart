import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final List<String> organizationIds;
  final String? defaultOrganizationId;
  final DateTime createdAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.organizationIds,
    this.defaultOrganizationId,
    required this.createdAt,
  });

  factory UserEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserEntity(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      organizationIds: List<String>.from(data['organizationIds'] as List? ?? []),
      defaultOrganizationId: data['defaultOrganizationId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'organizationIds': organizationIds,
      'defaultOrganizationId': defaultOrganizationId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    List<String>? organizationIds,
    String? defaultOrganizationId,
    DateTime? createdAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      organizationIds: organizationIds ?? this.organizationIds,
      defaultOrganizationId: defaultOrganizationId ?? this.defaultOrganizationId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        organizationIds,
        defaultOrganizationId,
        createdAt,
      ];
}
