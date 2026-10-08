// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: invalid_annotation_target

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: json['id'] as String,
  businessId: json['business_id'] as String,
  name: json['name'] as String,
  isDefault: json['is_default'] as bool? ?? false,
  isHidden: json['is_hidden'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'business_id': instance.businessId,
  'name': instance.name,
  'is_default': instance.isDefault,
  'is_hidden': instance.isHidden,
  'created_at': instance.createdAt.toIso8601String(),
};
