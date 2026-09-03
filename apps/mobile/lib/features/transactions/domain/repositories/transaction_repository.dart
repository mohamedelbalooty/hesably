import 'package:hesably_mobile/features/transactions/domain/models/transaction.dart';

abstract class TransactionRepository {
  /// Fetches transactions for a business with optional filters and pagination.
  Future<List<Transaction>> getTransactions({
    required String businessId,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  });

  /// Fetches a single transaction by ID.
  Future<Transaction?> getTransaction(String transactionId);

  /// Creates a new transaction.
  Future<Transaction> createTransaction(Transaction transaction);

  /// Updates an existing transaction.
  Future<Transaction> updateTransaction(Transaction transaction);

  /// Deletes a transaction.
  Future<void> deleteTransaction(String transactionId);
}
