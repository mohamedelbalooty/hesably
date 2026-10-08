import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hesably_mobile/features/transactions/domain/models/transaction.dart';
import 'package:hesably_mobile/features/transactions/domain/repositories/transaction_repository.dart';

// --- Events ---
abstract class TransactionListEvent extends Equatable {
  const TransactionListEvent();
  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionListEvent {
  final String businessId;
  const LoadTransactions(this.businessId);
  @override
  List<Object?> get props => [businessId];
}

class FilterTransactions extends TransactionListEvent {
  final String? type;
  final String? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  const FilterTransactions({
    this.type,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [type, categoryId, startDate, endDate, searchQuery];
}

class LoadMoreTransactions extends TransactionListEvent {}

// --- States ---
abstract class TransactionListState extends Equatable {
  final List<Transaction> transactions;
  final bool hasReachedMax;
  
  // Current filters
  final String businessId;
  final String? type;
  final String? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  const TransactionListState({
    this.transactions = const [],
    this.hasReachedMax = false,
    this.businessId = '',
    this.type,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [
    transactions, hasReachedMax, businessId, type, categoryId, startDate, endDate, searchQuery
  ];
}

class TransactionListInitial extends TransactionListState {}

class TransactionListLoading extends TransactionListState {
  const TransactionListLoading({
    super.transactions,
    super.hasReachedMax,
    required super.businessId,
    super.type,
    super.categoryId,
    super.startDate,
    super.endDate,
    super.searchQuery,
  });
}

class TransactionListLoaded extends TransactionListState {
  const TransactionListLoaded({
    required super.transactions,
    required super.hasReachedMax,
    required super.businessId,
    super.type,
    super.categoryId,
    super.startDate,
    super.endDate,
    super.searchQuery,
  });
}

class TransactionListError extends TransactionListState {
  final String error;
  const TransactionListError(this.error, {
    super.transactions,
    super.hasReachedMax,
    required super.businessId,
    super.type,
    super.categoryId,
    super.startDate,
    super.endDate,
    super.searchQuery,
  });

  @override
  List<Object?> get props => [...super.props, error];
}

// --- Bloc ---
class TransactionListBloc extends Bloc<TransactionListEvent, TransactionListState> {
  final TransactionRepository _repository;
  static const int _limit = 20;

  TransactionListBloc(this._repository) : super(TransactionListInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<FilterTransactions>(_onFilterTransactions);
    on<LoadMoreTransactions>(_onLoadMoreTransactions);
  }

  Future<void> _onLoadTransactions(LoadTransactions event, Emitter<TransactionListState> emit) async {
    emit(TransactionListLoading(
      businessId: event.businessId,
      transactions: const [],
      hasReachedMax: false,
    ));

    try {
      final txs = await _repository.getTransactions(
        businessId: event.businessId,
        limit: _limit,
        offset: 0,
      );
      
      emit(TransactionListLoaded(
        businessId: event.businessId,
        transactions: txs,
        hasReachedMax: txs.length < _limit,
      ));
    } catch (e) {
      emit(TransactionListError(
        e.toString(),
        businessId: event.businessId,
      ));
    }
  }

  Future<void> _onFilterTransactions(FilterTransactions event, Emitter<TransactionListState> emit) async {
    if (state.businessId.isEmpty) return;

    emit(TransactionListLoading(
      businessId: state.businessId,
      transactions: const [],
      hasReachedMax: false,
      type: event.type,
      categoryId: event.categoryId,
      startDate: event.startDate,
      endDate: event.endDate,
      searchQuery: event.searchQuery,
    ));

    try {
      final txs = await _repository.getTransactions(
        businessId: state.businessId,
        type: event.type,
        categoryId: event.categoryId,
        startDate: event.startDate,
        endDate: event.endDate,
        searchQuery: event.searchQuery,
        limit: _limit,
        offset: 0,
      );
      
      emit(TransactionListLoaded(
        businessId: state.businessId,
        transactions: txs,
        hasReachedMax: txs.length < _limit,
        type: event.type,
        categoryId: event.categoryId,
        startDate: event.startDate,
        endDate: event.endDate,
        searchQuery: event.searchQuery,
      ));
    } catch (e) {
      emit(TransactionListError(
        e.toString(),
        businessId: state.businessId,
        type: event.type,
        categoryId: event.categoryId,
        startDate: event.startDate,
        endDate: event.endDate,
        searchQuery: event.searchQuery,
      ));
    }
  }

  Future<void> _onLoadMoreTransactions(LoadMoreTransactions event, Emitter<TransactionListState> emit) async {
    if (state.hasReachedMax || state.businessId.isEmpty || state is TransactionListLoading) return;

    try {
      final newTxs = await _repository.getTransactions(
        businessId: state.businessId,
        type: state.type,
        categoryId: state.categoryId,
        startDate: state.startDate,
        endDate: state.endDate,
        searchQuery: state.searchQuery,
        limit: _limit,
        offset: state.transactions.length,
      );
      
      emit(TransactionListLoaded(
        businessId: state.businessId,
        transactions: List.of(state.transactions)..addAll(newTxs),
        hasReachedMax: newTxs.length < _limit,
        type: state.type,
        categoryId: state.categoryId,
        startDate: state.startDate,
        endDate: state.endDate,
        searchQuery: state.searchQuery,
      ));
    } catch (e) {
      emit(TransactionListError(
        e.toString(),
        businessId: state.businessId,
        transactions: state.transactions,
        hasReachedMax: state.hasReachedMax,
        type: state.type,
        categoryId: state.categoryId,
        startDate: state.startDate,
        endDate: state.endDate,
        searchQuery: state.searchQuery,
      ));
    }
  }
}
