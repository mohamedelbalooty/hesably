import 'package:flutter_test/flutter_test.dart';
import 'package:hesably_mobile/features/ai_extraction/domain/models/ai_extraction_draft.dart';

void main() {
  group('AiExtractionDraft', () {
    test('fromJson parses correctly', () {
      final json = {
        'is_receipt': true,
        'transaction_type': 'expense',
        'date': '2026-08-27',
        'total_amount': 150.0,
        'currency': 'EGP',
        'vendor_customer_name': 'Tech Store',
        'suggested_category': 'Electronics',
        'line_items': [
          {
            'description': 'Mouse',
            'quantity': 1.0,
            'unit_price': 150.0,
            'total_price': 150.0,
          }
        ],
        'confidence_scores': {
          'overall': 0.9,
          'date': 0.95,
          'total_amount': 0.99,
          'vendor_customer_name': 0.88,
        }
      };

      final draft = AiExtractionDraft.fromJson(json);

      expect(draft.isReceipt, true);
      expect(draft.transactionType, 'expense');
      expect(draft.totalAmount, 150.0);
      expect(draft.lineItems.length, 1);
      expect(draft.lineItems.first.description, 'Mouse');
      expect(draft.confidenceScores.overall, 0.9);
    });
  });
}
