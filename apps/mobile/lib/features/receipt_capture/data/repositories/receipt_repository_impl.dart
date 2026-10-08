import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/receipt_repository.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  final SupabaseClient _supabaseClient;
  final Uuid _uuid = const Uuid();

  ReceiptRepositoryImpl(this._supabaseClient);

  @override
  Future<String> uploadReceipt({
    required String localPath,
    required String businessId,
    required String transactionType,
  }) async {
    // 1. Compress image
    final compressedFile = await _compressImage(localPath);
    if (compressedFile == null) {
      throw Exception('Failed to compress image');
    }

    // 2. Generate unique filename
    final fileName = '${_uuid.v4()}.jpg';
    final storagePath = '$businessId/$fileName';

    // 3. Upload to Supabase Storage
    await _supabaseClient.storage.from('receipts').upload(
      storagePath,
      File(compressedFile.path),
      fileOptions: FileOptions(
        upsert: false,
        contentType: 'image/jpeg',
      ),
    );

    // Note: To set custom metadata on storage.objects, we would normally use 
    // the Supabase Management API or update the storage.objects table directly 
    // via a Postgres function, as the standard Flutter SDK upload doesn't 
    // accept arbitrary custom metadata beyond cacheControl and contentType.
    // However, the object path itself acts as basic metadata (business_id).
    // The transactionType will be linked in Sprint 3 when creating ai_extractions.

    return storagePath;
  }

  Future<XFile?> _compressImage(String filePath) async {
    final lastIndex = filePath.lastIndexOf(RegExp(r'.jp|.png|.heic|.webp', caseSensitive: false));
    final outPath = '${filePath.substring(0, lastIndex)}_compressed.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      outPath,
      quality: 70, // Adjust to balance size vs legibility
      minWidth: 1024,
      minHeight: 1024,
      format: CompressFormat.jpeg,
    );

    return result;
  }
}
