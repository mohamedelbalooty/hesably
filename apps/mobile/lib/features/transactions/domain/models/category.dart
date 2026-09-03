import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class Category {
  final String id;
  
  @JsonKey(name: 'business_id')
  final String businessId;
  
  final String name;
  
  @JsonKey(name: 'is_default')
  final bool isDefault;
  
  @JsonKey(name: 'is_hidden')
  final bool isHidden;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.businessId,
    required this.name,
    this.isDefault = false,
    this.isHidden = false,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  Category copyWith({
    String? id,
    String? businessId,
    String? name,
    bool? isDefault,
    bool? isHidden,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
