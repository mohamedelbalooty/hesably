abstract class ReceiptRepository {
  /// Compresses the image and uploads it to Supabase Storage.
  /// Returns the secure storage path of the uploaded file.
  Future<String> uploadReceipt({
    required String localPath,
    required String businessId,
    required String transactionType,
  });
}
