// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: invalid_annotation_target

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
  id: json['id'] as String,
  businessId: json['business_id'] as String,
  type: json['type'] as String,
  amount: (json['amount'] as num).toDouble(),
  date: DateTime.parse(json['date'] as String),
  categoryId: json['category_id'] as String,
  vendorCustomerName: json['vendor_customer_name'] as String?,
  receiptImagePath: json['receipt_image_path'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'business_id': instance.businessId,
      'type': instance.type,
      'amount': instance.amount,
      'date': instance.date.toIso8601String(),
      'category_id': instance.categoryId,
      'vendor_customer_name': instance.vendorCustomerName,
      'receipt_image_path': instance.receiptImagePath,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
