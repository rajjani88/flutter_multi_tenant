import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/audit_log_entity.dart';

class AuditRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  AuditRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream audit logs for a specific organization in reverse chronological order
  Stream<List<AuditLogEntity>> streamAuditLogs(String orgId) {
    if (orgId.isEmpty) return Stream.value([]);
    return _firestore
        .collection(AppConstants.organizationsCollection)
        .doc(orgId)
        .collection(AppConstants.auditLogsSubcollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AuditLogEntity.fromFirestore(d)).toList());
  }

  /// Append an immutable audit entry
  Future<void> recordLog({
    required String orgId,
    required String actorId,
    required String actorEmail,
    required String action,
    required String targetId,
    required String targetType,
    Map<String, dynamic> details = const {},
  }) async {
    final logId = _uuid.v4();
    final log = AuditLogEntity(
      id: logId,
      organizationId: orgId,
      actorId: actorId,
      actorEmail: actorEmail,
      action: action,
      targetId: targetId,
      targetType: targetType,
      timestamp: DateTime.now(),
      details: details,
    );

    await _firestore
        .collection(AppConstants.organizationsCollection)
        .doc(orgId)
        .collection(AppConstants.auditLogsSubcollection)
        .doc(logId)
        .set(log.toFirestore());
  }
}
