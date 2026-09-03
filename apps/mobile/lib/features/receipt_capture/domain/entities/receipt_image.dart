class ReceiptImage {
  final String localPath;
  final String transactionType; // 'income' or 'expense'
  final int sizeBytes;

  ReceiptImage({
    required this.localPath,
    required this.transactionType,
    required this.sizeBytes,
  });
}
