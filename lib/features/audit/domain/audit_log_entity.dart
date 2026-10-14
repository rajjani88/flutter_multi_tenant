import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AuditLogEntity extends Equatable {
  final String id;
  final String organizationId;
  final String actorId;
  final String actorEmail;
  final String action; // 'task_created', 'task_updated', 'task_deleted', 'member_invited', 'member_removed', 'role_changed', 'settings_updated'
  final String targetId;
  final String targetType; // 'task', 'member', 'organization'
  final DateTime timestamp;
  final Map<String, dynamic> details;

  const AuditLogEntity({
    required this.id,
    required this.organizationId,
    required this.actorId,
    required this.actorEmail,
    required this.action,
    required this.targetId,
    required this.targetType,
    required this.timestamp,
    this.details = const {},
  });

  factory AuditLogEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AuditLogEntity(
      id: doc.id,
      organizationId: data['organizationId'] as String? ?? '',
      actorId: data['actorId'] as String? ?? '',
      actorEmail: data['actorEmail'] as String? ?? '',
      action: data['action'] as String? ?? '',
      targetId: data['targetId'] as String? ?? '',
      targetType: data['targetType'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      details: Map<String, dynamic>.from(data['details'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'organizationId': organizationId,
      'actorId': actorId,
      'actorEmail': actorEmail,
      'action': action,
      'targetId': targetId,
      'targetType': targetType,
      'timestamp': Timestamp.fromDate(timestamp),
      'details': details,
    };
  }

  @override
  List<Object?> get props => [
        id,
        organizationId,
        actorId,
        actorEmail,
        action,
        targetId,
        targetType,
        timestamp,
        details,
      ];
}
