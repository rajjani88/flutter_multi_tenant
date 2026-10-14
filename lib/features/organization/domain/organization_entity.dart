import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class OrganizationEntity extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> settings;

  const OrganizationEntity({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.settings = const {},
  });

  factory OrganizationEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OrganizationEntity(
      id: doc.id,
      name: data['name'] as String? ?? 'Untitled Org',
      ownerId: data['ownerId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      settings: Map<String, dynamic>.from(data['settings'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'settings': settings,
    };
  }

  OrganizationEntity copyWith({
    String? id,
    String? name,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? settings,
  }) {
    return OrganizationEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [id, name, ownerId, createdAt, updatedAt, settings];
}
