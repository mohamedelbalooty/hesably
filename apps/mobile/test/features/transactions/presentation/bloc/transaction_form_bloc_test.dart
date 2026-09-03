import 'package:flutter_test/flutter_test.dart';
import 'package:hesably_mobile/features/transactions/domain/models/transaction.dart';
import 'package:hesably_mobile/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:hesably_mobile/features/transactions/presentation/bloc/transaction_form_bloc.dart';

class MockTransactionRepository implements TransactionRepository {
  bool throwError = false;

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    if (throwError) throw Exception('Create error');
    return transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    if (throwError) throw Exception('Delete error');
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
    throw UnimplementedError();
  }

  @override
  Future<Transaction?> getTransaction(String transactionId) async {
    return null;
  }

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    if (throwError) throw Exception('Update error');
    return transaction;
  }
}

void main() {
  late TransactionFormBloc bloc;
  late MockTransactionRepository mockRepo;
  final testTx = Transaction(
    id: '1',
    businessId: 'b1',
    type: 'expense',
    amount: 100,
    date: DateTime.now(),
    categoryId: 'c1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockRepo = MockTransactionRepository();
    bloc = TransactionFormBloc(mockRepo);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is TransactionFormInitial', () {
    expect(bloc.state, isA<TransactionFormInitial>());
  });

  test('emits Saving then Success on successful creation', () async {
    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<TransactionFormSaving>(),
        isA<TransactionFormSuccess>(),
      ]),
    );

    bloc.add(SaveTransaction(testTx, isEdit: false));
  });

  test('emits Saving then Success on successful update', () async {
    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<TransactionFormSaving>(),
        isA<TransactionFormSuccess>(),
      ]),
    );

    bloc.add(SaveTransaction(testTx, isEdit: true));
  });
  
  test('emits Deleting then DeleteSuccess on successful deletion', () async {
    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<TransactionFormDeleting>(),
        isA<TransactionFormDeleteSuccess>(),
      ]),
    );

    bloc.add(const DeleteTransaction('1'));
  });

  test('emits Saving then Failure on error', () async {
    mockRepo.throwError = true;

    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<TransactionFormSaving>(),
        isA<TransactionFormFailure>(),
      ]),
    );

    bloc.add(SaveTransaction(testTx));
  });
}
