import 'package:json_annotation/json_annotation.dart';

part 'ai_extraction_draft.g.dart';

@JsonSerializable()
class AiExtractionDraft {
  @JsonKey(name: 'is_receipt')
  final bool isReceipt;
  
  @JsonKey(name: 'transaction_type')
  final String transactionType;
  
  final String? date;
  
  @JsonKey(name: 'total_amount')
  final double? totalAmount;
  
  final String? currency;
  
  @JsonKey(name: 'vendor_customer_name')
  final String? vendorCustomerName;
  
  @JsonKey(name: 'suggested_category')
  final String? suggestedCategory;
  
  @JsonKey(name: 'line_items')
  final List<LineItem> lineItems;
  
  @JsonKey(name: 'confidence_scores')
  final ConfidenceScores confidenceScores;

  const AiExtractionDraft({
    required this.isReceipt,
    required this.transactionType,
    this.date,
    this.totalAmount,
    this.currency,
    this.vendorCustomerName,
    this.suggestedCategory,
    this.lineItems = const [],
    required this.confidenceScores,
  });

  factory AiExtractionDraft.fromJson(Map<String, dynamic> json) => _$AiExtractionDraftFromJson(json);
  Map<String, dynamic> toJson() => _$AiExtractionDraftToJson(this);
}

@JsonSerializable()
class LineItem {
  final String description;
  final double quantity;
  
  @JsonKey(name: 'unit_price')
  final double unitPrice;
  
  @JsonKey(name: 'total_price')
  final double totalPrice;

  const LineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory LineItem.fromJson(Map<String, dynamic> json) => _$LineItemFromJson(json);
  Map<String, dynamic> toJson() => _$LineItemToJson(this);
}

@JsonSerializable()
class ConfidenceScores {
  final double overall;
  final double date;
  
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  
  @JsonKey(name: 'vendor_customer_name')
  final double vendorCustomerName;

  const ConfidenceScores({
    required this.overall,
    required this.date,
    required this.totalAmount,
    required this.vendorCustomerName,
  });

  factory ConfidenceScores.fromJson(Map<String, dynamic> json) => _$ConfidenceScoresFromJson(json);
  Map<String, dynamic> toJson() => _$ConfidenceScoresToJson(this);
}
