import 'package:equatable/equatable.dart';

class BusinessEntity extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String type;
  final DateTime? createdAt;

  const BusinessEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'owner_id': ownerId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  BusinessEntity copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? type,
    DateTime? createdAt,
  }) {
    return BusinessEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, ownerId, name, type, createdAt];
}
