import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class TaskEntity extends Equatable {
  final String id;
  final String orgId;
  final String title;
  final String description;
  final String status; // 'To Do', 'In Progress', 'Done'
  final String priority; // 'Low', 'Medium', 'High', 'Urgent'
  final String? assigneeId;
  final String? assigneeName;
  final String creatorId;
  final String creatorName;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskEntity({
    required this.id,
    required this.orgId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    this.assigneeName,
    required this.creatorId,
    required this.creatorName,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TaskEntity(
      id: doc.id,
      orgId: data['orgId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'To Do',
      priority: data['priority'] as String? ?? 'Medium',
      assigneeId: data['assigneeId'] as String?,
      assigneeName: data['assigneeName'] as String?,
      creatorId: data['creatorId'] as String? ?? '',
      creatorName: data['creatorName'] as String? ?? 'Author',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'orgId': orgId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'creatorId': creatorId,
      'creatorName': creatorName,
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TaskEntity copyWith({
    String? id,
    String? orgId,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? assigneeId,
    String? assigneeName,
    String? creatorId,
    String? creatorName,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orgId,
        title,
        description,
        status,
        priority,
        assigneeId,
        assigneeName,
        creatorId,
        creatorName,
        dueDate,
        createdAt,
        updatedAt,
      ];
}
