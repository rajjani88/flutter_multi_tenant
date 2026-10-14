import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/audit_repository.dart';
import '../domain/audit_log_entity.dart';
import '../../organization/presentation/organization_providers.dart';

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository();
});

/// Stream of audit logs for active organization (ordered by timestamp descending)
final auditLogsStreamProvider = StreamProvider<List<AuditLogEntity>>((ref) {
  final activeOrgId = ref.watch(activeOrganizationIdProvider);
  if (activeOrgId == null) return Stream.value([]);
  final repo = ref.watch(auditRepositoryProvider);
  return repo.streamAuditLogs(activeOrgId);
});
