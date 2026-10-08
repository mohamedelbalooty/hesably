import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hesably_mobile/features/transactions/domain/models/transaction.dart';
import 'package:hesably_mobile/features/transactions/domain/repositories/transaction_repository.dart';

// --- Events ---
abstract class TransactionFormEvent extends Equatable {
  const TransactionFormEvent();
  @override
  List<Object?> get props => [];
}

class SaveTransaction extends TransactionFormEvent {
  final Transaction transaction;
  final bool isEdit;
  
  const SaveTransaction(this.transaction, {this.isEdit = false});
  
  @override
  List<Object?> get props => [transaction, isEdit];
}

class DeleteTransaction extends TransactionFormEvent {
  final String transactionId;
  
  const DeleteTransaction(this.transactionId);
  
  @override
  List<Object?> get props => [transactionId];
}

// --- States ---
abstract class TransactionFormState extends Equatable {
  const TransactionFormState();
  @override
  List<Object?> get props => [];
}

class TransactionFormInitial extends TransactionFormState {}
class TransactionFormSaving extends TransactionFormState {}
class TransactionFormDeleting extends TransactionFormState {}
class TransactionFormSuccess extends TransactionFormState {}
class TransactionFormDeleteSuccess extends TransactionFormState {}
class TransactionFormFailure extends TransactionFormState {
  final String error;
  const TransactionFormFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// --- Bloc ---
class TransactionFormBloc extends Bloc<TransactionFormEvent, TransactionFormState> {
  final TransactionRepository _repository;

  TransactionFormBloc(this._repository) : super(TransactionFormInitial()) {
    on<SaveTransaction>(_onSaveTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
  }

  Future<void> _onSaveTransaction(SaveTransaction event, Emitter<TransactionFormState> emit) async {
    emit(TransactionFormSaving());
    try {
      if (event.isEdit) {
        await _repository.updateTransaction(event.transaction);
      } else {
        await _repository.createTransaction(event.transaction);
      }
      emit(TransactionFormSuccess());
    } catch (e) {
      emit(TransactionFormFailure(e.toString()));
    }
  }

  Future<void> _onDeleteTransaction(DeleteTransaction event, Emitter<TransactionFormState> emit) async {
    emit(TransactionFormDeleting());
    try {
      await _repository.deleteTransaction(event.transactionId);
      emit(TransactionFormDeleteSuccess());
    } catch (e) {
      emit(TransactionFormFailure(e.toString()));
    }
  }
}
