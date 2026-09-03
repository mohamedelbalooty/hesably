import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:hesably_mobile/features/receipt_capture/domain/repositories/receipt_repository.dart';
import 'package:hesably_mobile/features/receipt_capture/presentation/bloc/receipt_capture_bloc.dart';

import 'receipt_capture_bloc_test.mocks.dart';

@GenerateMocks([ReceiptRepository])
void main() {
  late ReceiptCaptureBloc receiptCaptureBloc;
  late MockReceiptRepository mockReceiptRepository;

  setUp(() {
    mockReceiptRepository = MockReceiptRepository();
    receiptCaptureBloc = ReceiptCaptureBloc(mockReceiptRepository);
  });

  tearDown(() {
    receiptCaptureBloc.close();
  });

  group('ReceiptCaptureBloc', () {
    test('initial state is ReceiptCaptureInitial', () {
      expect(receiptCaptureBloc.state, const ReceiptCaptureInitial());
    });

    blocTest<ReceiptCaptureBloc, ReceiptCaptureState>(
      'emits [ReceiptCaptureTypeSelected] when SelectTransactionType is added',
      build: () => receiptCaptureBloc,
      act: (bloc) => bloc.add(const SelectTransactionType('expense')),
      expect: () => [
        const ReceiptCaptureTypeSelected('expense'),
      ],
    );

    blocTest<ReceiptCaptureBloc, ReceiptCaptureState>(
      'emits [ReceiptCaptureImagePicked] when CaptureReceiptImage is added after type selection',
      build: () => receiptCaptureBloc,
      seed: () => const ReceiptCaptureTypeSelected('expense'),
      act: (bloc) => bloc.add(const CaptureReceiptImage('/path/to/image.jpg')),
      expect: () => [
        const ReceiptCaptureImagePicked('expense', '/path/to/image.jpg'),
      ],
    );

    blocTest<ReceiptCaptureBloc, ReceiptCaptureState>(
      'does not emit when CaptureReceiptImage is added but no type selected',
      build: () => receiptCaptureBloc,
      act: (bloc) => bloc.add(const CaptureReceiptImage('/path/to/image.jpg')),
      expect: () => [],
    );

    blocTest<ReceiptCaptureBloc, ReceiptCaptureState>(
      'emits [ReceiptCaptureLoading, ReceiptCaptureSuccess] when UploadReceipt is successful',
      build: () {
        when(mockReceiptRepository.uploadReceipt(
          localPath: '/path/to/image.jpg',
          businessId: 'test-business-id',
          transactionType: 'expense',
        )).thenAnswer((_) async => 'receipts/test-business-id/123.jpg');
        return receiptCaptureBloc;
      },
      seed: () => const ReceiptCaptureImagePicked('expense', '/path/to/image.jpg'),
      act: (bloc) => bloc.add(const UploadReceipt('test-business-id')),
      expect: () => [
        const ReceiptCaptureLoading('expense', '/path/to/image.jpg'),
        const ReceiptCaptureSuccess('expense', '/path/to/image.jpg', 'receipts/test-business-id/123.jpg'),
      ],
    );

    blocTest<ReceiptCaptureBloc, ReceiptCaptureState>(
      'emits [ReceiptCaptureLoading, ReceiptCaptureFailure] when UploadReceipt fails',
      build: () {
        when(mockReceiptRepository.uploadReceipt(
          localPath: '/path/to/image.jpg',
          businessId: 'test-business-id',
          transactionType: 'expense',
        )).thenThrow(Exception('Upload failed'));
        return receiptCaptureBloc;
      },
      seed: () => const ReceiptCaptureImagePicked('expense', '/path/to/image.jpg'),
      act: (bloc) => bloc.add(const UploadReceipt('test-business-id')),
      expect: () => [
        const ReceiptCaptureLoading('expense', '/path/to/image.jpg'),
        const ReceiptCaptureFailure('expense', '/path/to/image.jpg', 'Exception: Upload failed'),
      ],
    );
  });
}
