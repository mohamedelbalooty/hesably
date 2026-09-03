import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hesably_mobile/features/ai_extraction/domain/models/ai_extraction_draft.dart';
import 'package:hesably_mobile/features/ai_extraction/domain/repositories/ai_extraction_repository.dart';
import 'package:hesably_mobile/features/ai_extraction/presentation/bloc/ai_extraction_bloc.dart';

class MockAiExtractionRepository extends Mock implements AiExtractionRepository {}

void main() {
  late AiExtractionBloc bloc;
  late MockAiExtractionRepository mockRepo;

  setUp(() {
    mockRepo = MockAiExtractionRepository();
    bloc = AiExtractionBloc(mockRepo);
  });

  tearDown(() {
    bloc.close();
  });

  const dummyDraft = AiExtractionDraft(
    isReceipt: true,
    confidenceScores: ConfidenceScores(
      overall: 0.95,
      totalAmount: 0.90,
      date: 0.92,
      vendorCustomerName: 0.88,
    ),
    transactionType: 'expense',
    totalAmount: 150.0,
    date: '2026-09-03',
    vendorCustomerName: 'Cairo Market',
    suggestedCategory: 'Groceries',
  );

  group('AiExtractionBloc', () {
    test('initial state is AiExtractionInitial', () {
      expect(bloc.state, isA<AiExtractionInitial>());
    });

    blocTest<AiExtractionBloc, AiExtractionState>(
      'emits [AiExtractionLoading, AiExtractionSuccess] when extraction succeeds',
      build: () {
        when(() => mockRepo.extractReceipt(
              businessId: 'biz-123',
              receiptImagePath: 'receipts/test.jpg',
            )).thenAnswer((_) async => dummyDraft);
        return bloc;
      },
      act: (bloc) => bloc.add(const StartExtraction(
        businessId: 'biz-123',
        receiptImagePath: 'receipts/test.jpg',
      )),
      expect: () => [
        isA<AiExtractionLoading>(),
        const AiExtractionSuccess(dummyDraft),
      ],
    );

    blocTest<AiExtractionBloc, AiExtractionState>(
      'emits [AiExtractionLoading, AiExtractionFailure] on timeout or error',
      build: () {
        when(() => mockRepo.extractReceipt(
              businessId: 'biz-123',
              receiptImagePath: 'receipts/test.jpg',
            )).thenThrow(Exception('Network timeout. Please check your connection.'));
        return bloc;
      },
      act: (bloc) => bloc.add(const StartExtraction(
        businessId: 'biz-123',
        receiptImagePath: 'receipts/test.jpg',
      )),
      expect: () => [
        isA<AiExtractionLoading>(),
        const AiExtractionFailure('Exception: Network timeout. Please check your connection.'),
      ],
    );
  });
}
