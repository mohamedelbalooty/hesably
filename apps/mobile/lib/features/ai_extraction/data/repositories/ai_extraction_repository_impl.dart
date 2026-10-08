import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/ai_extraction_draft.dart';
import '../../domain/repositories/ai_extraction_repository.dart';

class AiExtractionRepositoryImpl implements AiExtractionRepository {
  final SupabaseClient _supabaseClient;

  AiExtractionRepositoryImpl(this._supabaseClient);

  @override
  Future<AiExtractionDraft> extractReceipt({
    required String businessId,
    required String receiptImagePath,
  }) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'extract-receipt',
        body: {
          'business_id': businessId,
          'receipt_image_path': receiptImagePath,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.status == 200 && response.data != null) {
        return AiExtractionDraft.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to extract receipt: ${response.status} - ${response.data}');
      }
    } on TimeoutException {
      throw Exception('Network timeout. Please check your connection or enter manually.');
    } on SocketException {
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      throw Exception('Extraction error: $e');
    }
  }
}
