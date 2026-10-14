import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'role_matrix.dart';

class MemberEntity extends Equatable {
  final String userId;
  final String email;
  final String displayName;
  final AppRole role;
  final DateTime joinedAt;
  final String? invitedBy;

  const MemberEntity({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    this.invitedBy,
  });

  factory MemberEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MemberEntity(
      userId: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? (data['email'] as String? ?? 'Member'),
      role: AppRole.fromString(data['role'] as String?),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      invitedBy: data['invitedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'role': role.value,
      'joinedAt': Timestamp.fromDate(joinedAt),
      if (invitedBy != null) 'invitedBy': invitedBy,
    };
  }

  MemberEntity copyWith({
    String? userId,
    String? email,
    String? displayName,
    AppRole? role,
    DateTime? joinedAt,
    String? invitedBy,
  }) {
    return MemberEntity(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      invitedBy: invitedBy ?? this.invitedBy,
    );
  }

  @override
  List<Object?> get props => [userId, email, displayName, role, joinedAt, invitedBy];
}
