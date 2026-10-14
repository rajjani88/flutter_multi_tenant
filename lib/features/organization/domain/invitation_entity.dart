import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'role_matrix.dart';

class InvitationEntity extends Equatable {
  final String id;
  final String organizationId;
  final String organizationName;
  final String email;
  final AppRole role;
  final String invitedBy;
  final String invitedByEmail;
  final String status; // 'pending' | 'accepted' | 'declined'
  final DateTime createdAt;

  const InvitationEntity({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.email,
    required this.role,
    required this.invitedBy,
    required this.invitedByEmail,
    this.status = 'pending',
    required this.createdAt,
  });

  factory InvitationEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InvitationEntity(
      id: doc.id,
      organizationId: data['organizationId'] as String? ?? '',
      organizationName: data['organizationName'] as String? ?? 'Workspace',
      email: data['email'] as String? ?? '',
      role: AppRole.fromString(data['role'] as String?),
      invitedBy: data['invitedBy'] as String? ?? '',
      invitedByEmail: data['invitedByEmail'] as String? ?? 'Admin',
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'email': email.toLowerCase().trim(),
      'role': role.value,
      'invitedBy': invitedBy,
      'invitedByEmail': invitedByEmail,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.now(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        organizationId,
        organizationName,
        email,
        role,
        invitedBy,
        invitedByEmail,
        status,
        createdAt,
      ];
}
