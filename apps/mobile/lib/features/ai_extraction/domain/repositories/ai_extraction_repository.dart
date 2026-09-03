import '../models/ai_extraction_draft.dart';

abstract class AiExtractionRepository {
  Future<AiExtractionDraft> extractReceipt({
    required String businessId,
    required String receiptImagePath,
  });
}
