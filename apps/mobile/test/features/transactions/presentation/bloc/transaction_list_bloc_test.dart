import 'package:flutter_test/flutter_test.dart';
import 'package:hesably_mobile/features/transactions/domain/models/transaction.dart';
import 'package:hesably_mobile/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:hesably_mobile/features/transactions/presentation/bloc/transaction_list_bloc.dart';

class MockTransactionRepository implements TransactionRepository {
  List<Transaction> transactionsToReturn = [];
  bool throwError = false;

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Transaction?> getTransaction(String transactionId) async {
    return null;
  }

  @override
  Future<List<Transaction>> getTransactions({
    required String businessId,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    if (throwError) throw Exception('Fetch error');
    return transactionsToReturn;
  }

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    throw UnimplementedError();
  }
}

void main() {
  late TransactionListBloc bloc;
  late MockTransactionRepository mockRepo;

  setUp(() {
    mockRepo = MockTransactionRepository();
    bloc = TransactionListBloc(mockRepo);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is TransactionListInitial', () {
    expect(bloc.state, isA<TransactionListInitial>());
  });

  test('emits Loading then Loaded on successful LoadTransactions', () async {
    mockRepo.transactionsToReturn = [
      Transaction(
        id: '1',
        businessId: 'b1',
        type: 'expense',
        amount: 100,
        date: DateTime.now(),
        categoryId: 'c1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )
    ];

    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<TransactionListLoading>(),
        isA<TransactionListLoaded>().having((s) => s.transactions.length, 'length', 1),
      ]),
    );

    bloc.add(const LoadTransactions('b1'));
  });

  test('emits Loading then Error on failed LoadTransactions', () async {
    mockRepo.throwError = true;

    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<TransactionListLoading>(),
        isA<TransactionListError>(),
      ]),
    );

    bloc.add(const LoadTransactions('b1'));
  });
}
