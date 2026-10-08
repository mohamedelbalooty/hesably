// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: invalid_annotation_target

part of 'ai_extraction_draft.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AiExtractionDraft _$AiExtractionDraftFromJson(Map<String, dynamic> json) =>
    AiExtractionDraft(
      isReceipt: json['is_receipt'] as bool,
      transactionType: json['transaction_type'] as String,
      date: json['date'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      vendorCustomerName: json['vendor_customer_name'] as String?,
      suggestedCategory: json['suggested_category'] as String?,
      lineItems:
          (json['line_items'] as List<dynamic>?)
              ?.map((e) => LineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      confidenceScores: ConfidenceScores.fromJson(
        json['confidence_scores'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$AiExtractionDraftToJson(AiExtractionDraft instance) =>
    <String, dynamic>{
      'is_receipt': instance.isReceipt,
      'transaction_type': instance.transactionType,
      'date': instance.date,
      'total_amount': instance.totalAmount,
      'currency': instance.currency,
      'vendor_customer_name': instance.vendorCustomerName,
      'suggested_category': instance.suggestedCategory,
      'line_items': instance.lineItems,
      'confidence_scores': instance.confidenceScores,
    };

LineItem _$LineItemFromJson(Map<String, dynamic> json) => LineItem(
  description: json['description'] as String,
  quantity: (json['quantity'] as num).toDouble(),
  unitPrice: (json['unit_price'] as num).toDouble(),
  totalPrice: (json['total_price'] as num).toDouble(),
);

Map<String, dynamic> _$LineItemToJson(LineItem instance) => <String, dynamic>{
  'description': instance.description,
  'quantity': instance.quantity,
  'unit_price': instance.unitPrice,
  'total_price': instance.totalPrice,
};

ConfidenceScores _$ConfidenceScoresFromJson(Map<String, dynamic> json) =>
    ConfidenceScores(
      overall: (json['overall'] as num).toDouble(),
      date: (json['date'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      vendorCustomerName: (json['vendor_customer_name'] as num).toDouble(),
    );

Map<String, dynamic> _$ConfidenceScoresToJson(ConfidenceScores instance) =>
    <String, dynamic>{
      'overall': instance.overall,
      'date': instance.date,
      'total_amount': instance.totalAmount,
      'vendor_customer_name': instance.vendorCustomerName,
    };
