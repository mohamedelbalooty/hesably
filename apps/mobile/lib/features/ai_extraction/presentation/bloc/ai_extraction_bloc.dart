import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/models/ai_extraction_draft.dart';
import '../../domain/repositories/ai_extraction_repository.dart';

// --- Events ---
abstract class AiExtractionEvent extends Equatable {
  const AiExtractionEvent();

  @override
  List<Object?> get props => [];
}

class StartExtraction extends AiExtractionEvent {
  final String businessId;
  final String receiptImagePath;

  const StartExtraction({
    required this.businessId,
    required this.receiptImagePath,
  });

  @override
  List<Object?> get props => [businessId, receiptImagePath];
}

// --- States ---
abstract class AiExtractionState extends Equatable {
  const AiExtractionState();

  @override
  List<Object?> get props => [];
}

class AiExtractionInitial extends AiExtractionState {}

class AiExtractionLoading extends AiExtractionState {}

class AiExtractionSuccess extends AiExtractionState {
  final AiExtractionDraft draft;
  const AiExtractionSuccess(this.draft);

  @override
  List<Object?> get props => [draft];
}

class AiExtractionFailure extends AiExtractionState {
  final String error;
  const AiExtractionFailure(this.error);

  @override
  List<Object?> get props => [error];
}

// --- Bloc ---
class AiExtractionBloc extends Bloc<AiExtractionEvent, AiExtractionState> {
  final AiExtractionRepository _repository;

  AiExtractionBloc(this._repository) : super(AiExtractionInitial()) {
    on<StartExtraction>((event, emit) async {
      emit(AiExtractionLoading());
      try {
        final draft = await _repository.extractReceipt(
          businessId: event.businessId,
          receiptImagePath: event.receiptImagePath,
        );
        emit(AiExtractionSuccess(draft));
      } catch (e) {
        emit(AiExtractionFailure(e.toString()));
      }
    });
  }
}
