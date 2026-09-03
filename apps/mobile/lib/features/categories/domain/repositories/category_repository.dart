import 'package:hesably_mobile/features/transactions/domain/models/category.dart';

abstract class CategoryRepository {
  /// Fetches all categories for a business.
  Future<List<Category>> getCategories(String businessId);
  
  /// Fetches all active categories for a business (not hidden).
  Future<List<Category>> getActiveCategories(String businessId);
  
  /// Adds a custom category for a business.
  Future<Category> addCustomCategory(String businessId, String name);

  /// Hides a default category.
  Future<void> hideDefaultCategory(String categoryId);
  
  /// Unhides a default category.
  Future<void> unhideDefaultCategory(String categoryId);
  
  /// Deletes a custom category.
  /// Throws an error if the category is used in transactions.
  Future<void> deleteCustomCategory(String categoryId);
  
  /// Reassigns transactions from one category to another.
  Future<void> reassignTransactions(String oldCategoryId, String newCategoryId);

  /// Reassigns transactions and then deletes the old category.
  Future<void> reassignAndDeleteCategory(String oldCategoryId, String newCategoryId);
}
