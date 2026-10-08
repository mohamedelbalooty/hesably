import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:hesably_mobile/features/transactions/domain/models/transaction.dart';
import 'package:hesably_mobile/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final supabase.SupabaseClient _client;

  TransactionRepositoryImpl(this._client);

  @override
  Future<List<Transaction>> getTransactions({
    required String businessId,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client
        .from('transactions')
        .select();

    query = query.eq('business_id', businessId);

    if (type != null) {
      query = query.eq('type', type);
    }
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (startDate != null) {
      final startStr = startDate.toUtc().toIso8601String().split('T')[0];
      query = query.gte('date', startStr);
    }
    if (endDate != null) {
      final endStr = endDate.toUtc().toIso8601String().split('T')[0];
      query = query.lte('date', endStr);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('vendor_customer_name', '%$searchQuery%');
    }

    final response = await query
        .order('date', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return response.map((json) => Transaction.fromJson(json)).toList();
  }

  @override
  Future<Transaction?> getTransaction(String transactionId) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('id', transactionId)
        .maybeSingle();
        
    if (response == null) return null;
    return Transaction.fromJson(response);
  }

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    final map = transaction.toJson();
    map.remove('id'); // Let DB generate ID
    map.remove('created_at');
    map.remove('updated_at');
    
    // Ensure date is formatted correctly for Supabase DATE type
    map['date'] = transaction.date.toUtc().toIso8601String().split('T')[0];

    final response = await _client
        .from('transactions')
        .insert(map)
        .select()
        .single();
        
    return Transaction.fromJson(response);
  }

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    final map = transaction.toJson();
    map.remove('created_at');
    map.remove('updated_at');
    
    map['date'] = transaction.date.toUtc().toIso8601String().split('T')[0];

    final response = await _client
        .from('transactions')
        .update(map)
        .eq('id', transaction.id)
        .select()
        .single();
        
    return Transaction.fromJson(response);
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await _client
        .from('transactions')
        .delete()
        .eq('id', transactionId);
  }
}
