import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/task_entity.dart';

class TaskRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  TaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Real-time stream of all tasks for a specific organization
  Stream<List<TaskEntity>> streamTasks(String orgId) {
    if (orgId.isEmpty) return Stream.value([]);
    return _firestore
        .collection(AppConstants.organizationsCollection)
        .doc(orgId)
        .collection(AppConstants.tasksSubcollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TaskEntity.fromFirestore(d)).toList());
  }

  /// Create a new task and record in audit log atomically
  Future<String> createTask({
    required String orgId,
    required String title,
    required String description,
    required String status,
    required String priority,
    String? assigneeId,
    String? assigneeName,
    required String creatorId,
    required String creatorName,
    required String creatorEmail,
    DateTime? dueDate,
  }) async {
    final taskId = _uuid.v4();
    final now = DateTime.now();
    final batch = _firestore.batch();

    final taskRef = _firestore
        .collection(AppConstants.organizationsCollection)
        .doc(orgId)
        .collection(AppConstants.tasksSubcollection)
        .doc(taskId);

    final task = TaskEntity(
      id: taskId,
      orgId: orgId,
      title: title.trim(),
      description: description.trim(),
      status: status,
      priority: priority,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      creatorId: creatorId,
      creatorName: creatorName,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
    );
    batch.set(taskRef, task.toFirestore());

    // Record audit log
    final logId = _uuid.v4();
    final auditRef = _firestore
        .collection(AppConstants.organizationsCollection)
        .doc(orgId)
        .collection(AppConstants.auditLogsSubcollection)
        .doc(logId);

    batch.set(auditRef, {
      'id': logId,
      'organizationId': orgId,
      'actorId': creatorId,
      'actorEmail': creatorEmail,
      'action': 'task_created',
      'targetId': taskId,
      'targetType': 'task',
      'timestamp': Timestamp.fromDate(now),
      'details': {
        'title': title.trim(),
        'status': status,
        'priority': priority,
        'assigneeName': assigneeName,
      },
    });

    await batch.commit();
    return taskId;
  }

  /// Update an existing task and record in audit log
  Future<void> updateTask({
    required TaskEntity oldTask,
    required TaskEntity updatedTask,
    required String actorId,
    required String actorEmail,
  }) async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    final taskRef = _firestore
        .collection(AppConstants.organizationsCollection)
        .doc(updatedTask.orgId)
        .collection(AppConstants.tasksSubcollection)
        .doc(updatedTask.id);

    final finalTask = updatedTask.copyWith(updatedAt: now);
    batch.update(taskRef, finalTask.toFirestore());

    // Determine change metadata for audit log
    final diff = <String, dynamic>{};
    if (oldTask.title != updatedTask.title) {
      diff['title'] = {'from': oldTask.title, 'to': updatedTask.title};
    }
    if (oldTask.status != updatedTask.status) {
      diff['status'] = {'from': oldTask.status, 'to': updatedTask.status};
    }
    if (oldTask.priority != updatedTask.priority) {
      diff['priority'] = {'from': oldTask.priority, 'to': updatedTask.priority};
    }
    if (oldTask.assigneeId != updatedTask.assigneeId) {
      diff['assignee'] = {
        'from': oldTask.assigneeName,
        'to': updatedTask.assigneeName
      };
    }
    if (oldTask.dueDate != updatedTask.dueDate) {
      diff['dueDate'] = {
        'from': oldTask.dueDate?.toIso8601String(),
        'to': updatedTask.dueDate?.toIso8601String(),
      };
    }

    final logId = _uuid.v4();
    final auditRef = _firestore
        .collection(AppConstants.organizationsCollection)
        .doc(updatedTask.orgId)
        .collection(AppConstants.auditLogsSubcollection)
        .doc(logId);

    batch.set(auditRef, {
      'id': logId,
      'organizationId': updatedTask.orgId,
      'actorId': actorId,
      'actorEmail': actorEmail,
      'action': 'task_updated',
      'targetId': updatedTask.id,
      'targetType': 'task',
      'timestamp': Timestamp.fromDate(now),
      'details': diff.isNotEmpty ? diff : {'action': 'content_edit'},
    });

    await batch.commit();
  }

  /// Delete a task and record in audit log
  Future<void> deleteTask({
    required TaskEntity task,
    required String actorId,
    required String actorEmail,
  }) async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    final taskRef = _firestore
        .collection(AppConstants.organizationsCollection)
        .doc(task.orgId)
        .collection(AppConstants.tasksSubcollection)
        .doc(task.id);

    batch.delete(taskRef);

    // Record audit log
    final logId = _uuid.v4();
    final auditRef = _firestore
        .collection(AppConstants.organizationsCollection)
        .doc(task.orgId)
        .collection(AppConstants.auditLogsSubcollection)
        .doc(logId);

    batch.set(auditRef, {
      'id': logId,
      'organizationId': task.orgId,
      'actorId': actorId,
      'actorEmail': actorEmail,
      'action': 'task_deleted',
      'targetId': task.id,
      'targetType': 'task',
      'timestamp': Timestamp.fromDate(now),
      'details': {
        'title': task.title,
        'lastStatus': task.status,
      },
    });

    await batch.commit();
  }
}
