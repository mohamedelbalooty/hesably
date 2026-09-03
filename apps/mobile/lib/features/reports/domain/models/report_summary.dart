import 'package:equatable/equatable.dart';

class CategorySummary extends Equatable {
  final String categoryId;
  final String categoryName;
  final double totalAmount;

  const CategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [categoryId, categoryName, totalAmount];
}

class ReportSummary extends Equatable {
  final double totalIncome;
  final double totalExpense;
  final double net;
  final List<CategorySummary> expenseCategories;
  final List<CategorySummary> incomeCategories;
  final double? previousPeriodTotalIncome;
  final double? previousPeriodTotalExpense;

  const ReportSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
    required this.expenseCategories,
    required this.incomeCategories,
    this.previousPeriodTotalIncome,
    this.previousPeriodTotalExpense,
  });

  @override
  List<Object?> get props => [
        totalIncome,
        totalExpense,
        net,
        expenseCategories,
        incomeCategories,
        previousPeriodTotalIncome,
        previousPeriodTotalExpense,
      ];
}
