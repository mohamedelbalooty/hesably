import 'package:json_annotation/json_annotation.dart';

part 'transaction.g.dart';

@JsonSerializable()
class Transaction {
  final String id;
  
  @JsonKey(name: 'business_id')
  final String businessId;
  
  final String type; // 'income' or 'expense'
  
  final double amount;
  
  final DateTime date;
  
  @JsonKey(name: 'category_id')
  final String categoryId;
  
  @JsonKey(name: 'vendor_customer_name')
  final String? vendorCustomerName;
  
  @JsonKey(name: 'receipt_image_path')
  final String? receiptImagePath;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.businessId,
    required this.type,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.vendorCustomerName,
    this.receiptImagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  Transaction copyWith({
    String? id,
    String? businessId,
    String? type,
    double? amount,
    DateTime? date,
    String? categoryId,
    String? vendorCustomerName,
    String? receiptImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      vendorCustomerName: vendorCustomerName ?? this.vendorCustomerName,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
