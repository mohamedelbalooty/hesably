import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:hesably_mobile/core/theme/app_theme.dart';
import 'package:hesably_mobile/features/categories/domain/repositories/category_repository.dart';
import 'package:hesably_mobile/features/ai_extraction/domain/models/ai_extraction_draft.dart';
import 'package:hesably_mobile/features/ai_extraction/presentation/bloc/ai_extraction_bloc.dart';
import 'package:hesably_mobile/features/ai_extraction/presentation/pages/review_edit_screen.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockAiExtractionBloc extends Mock implements AiExtractionBloc {}

void main() {
  late MockCategoryRepository mockCategoryRepository;
  late MockAiExtractionBloc mockAiExtractionBloc;

  setUp(() {
    mockCategoryRepository = MockCategoryRepository();
    mockAiExtractionBloc = MockAiExtractionBloc();

    GetIt.instance.reset();
    GetIt.instance.registerSingleton<CategoryRepository>(mockCategoryRepository);
    when(() => mockCategoryRepository.getActiveCategories(any())).thenAnswer((_) async => []);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  testWidgets('ReviewEditView shows warning icon when confidence score is low', (tester) async {
    const lowConfidenceDraft = AiExtractionDraft(
      isReceipt: true,
      confidenceScores: ConfidenceScores(
        overall: 0.50,
        totalAmount: 0.40, // < 0.70 triggers warning
        date: 0.90,
        vendorCustomerName: 0.90,
      ),
      transactionType: 'expense',
      totalAmount: 250.0,
      date: '2026-09-03',
      vendorCustomerName: 'Cairo Market',
      suggestedCategory: 'Groceries',
    );

    when(() => mockAiExtractionBloc.state).thenReturn(
      const AiExtractionSuccess(lowConfidenceDraft),
    );
    when(() => mockAiExtractionBloc.stream).thenAnswer(
      (_) => Stream.value(const AiExtractionSuccess(lowConfidenceDraft)),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BlocProvider<AiExtractionBloc>.value(
          value: mockAiExtractionBloc,
          child: const ReviewEditView(
            storagePath: 'receipts/test.jpg',
            businessId: 'test-business-id',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify low confidence container icon renders
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
  });
}
