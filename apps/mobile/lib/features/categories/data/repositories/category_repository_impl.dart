import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:hesably_mobile/features/categories/domain/repositories/category_repository.dart';
import 'package:hesably_mobile/features/transactions/domain/models/category.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final supabase.SupabaseClient _client;

  CategoryRepositoryImpl(this._client);

  @override
  Future<List<Category>> getCategories(String businessId) async {
    final response = await _client
        .from('categories')
        .select()
        .eq('business_id', businessId)
        .order('name', ascending: true);
        
    return response.map((json) => Category.fromJson(json)).toList();
  }

  @override
  Future<List<Category>> getActiveCategories(String businessId) async {
    final response = await _client
        .from('categories')
        .select()
        .eq('business_id', businessId)
        .eq('is_hidden', false)
        .order('name', ascending: true);
        
    return response.map((json) => Category.fromJson(json)).toList();
  }

  @override
  Future<Category> addCustomCategory(String businessId, String name) async {
    final response = await _client
        .from('categories')
        .insert({
          'business_id': businessId,
          'name': name,
          'is_default': false,
          'is_hidden': false,
        })
        .select()
        .single();
        
    return Category.fromJson(response);
  }

  @override
  Future<void> hideDefaultCategory(String categoryId) async {
    await _client
        .from('categories')
        .update({'is_hidden': true})
        .eq('id', categoryId)
        .eq('is_default', true);
  }

  @override
  Future<void> unhideDefaultCategory(String categoryId) async {
    await _client
        .from('categories')
        .update({'is_hidden': false})
        .eq('id', categoryId)
        .eq('is_default', true);
  }

  @override
  Future<void> deleteCustomCategory(String categoryId) async {
    await _client
        .from('categories')
        .delete()
        .eq('id', categoryId)
        .eq('is_default', false);
  }

  @override
  Future<void> reassignTransactions(String oldCategoryId, String newCategoryId) async {
    await _client
        .from('transactions')
        .update({'category_id': newCategoryId})
        .eq('category_id', oldCategoryId);
  }

  @override
  Future<void> reassignAndDeleteCategory(String oldCategoryId, String newCategoryId) async {
    // 1. Reassign all transactions
    await reassignTransactions(oldCategoryId, newCategoryId);
    // 2. Delete the custom category
    await deleteCustomCategory(oldCategoryId);
  }
}
