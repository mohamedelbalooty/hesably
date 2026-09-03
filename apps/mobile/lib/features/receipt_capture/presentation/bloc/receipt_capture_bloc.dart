import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/repositories/receipt_repository.dart';

// --- Events ---
abstract class ReceiptCaptureEvent extends Equatable {
  const ReceiptCaptureEvent();

  @override
  List<Object?> get props => [];
}

class SelectTransactionType extends ReceiptCaptureEvent {
  final String type;
  const SelectTransactionType(this.type);

  @override
  List<Object?> get props => [type];
}

class CaptureReceiptImage extends ReceiptCaptureEvent {
  final String localPath;
  const CaptureReceiptImage(this.localPath);

  @override
  List<Object?> get props => [localPath];
}

class UploadReceipt extends ReceiptCaptureEvent {
  final String businessId;
  const UploadReceipt(this.businessId);

  @override
  List<Object?> get props => [businessId];
}

// --- States ---
abstract class ReceiptCaptureState extends Equatable {
  final String? transactionType;
  final String? localPath;

  const ReceiptCaptureState({this.transactionType, this.localPath});

  @override
  List<Object?> get props => [transactionType, localPath];
}

class ReceiptCaptureInitial extends ReceiptCaptureState {
  const ReceiptCaptureInitial() : super();
}

class ReceiptCaptureTypeSelected extends ReceiptCaptureState {
  const ReceiptCaptureTypeSelected(String type) : super(transactionType: type);
}

class ReceiptCaptureImagePicked extends ReceiptCaptureState {
  const ReceiptCaptureImagePicked(String type, String path)
      : super(transactionType: type, localPath: path);
}

class ReceiptCaptureLoading extends ReceiptCaptureState {
  const ReceiptCaptureLoading(String type, String path)
      : super(transactionType: type, localPath: path);
}

class ReceiptCaptureSuccess extends ReceiptCaptureState {
  final String storagePath;
  const ReceiptCaptureSuccess(String type, String path, this.storagePath)
      : super(transactionType: type, localPath: path);

  @override
  List<Object?> get props => [transactionType, localPath, storagePath];
}

class ReceiptCaptureFailure extends ReceiptCaptureState {
  final String error;
  const ReceiptCaptureFailure(String type, String? path, this.error)
      : super(transactionType: type, localPath: path);

  @override
  List<Object?> get props => [transactionType, localPath, error];
}

// --- Bloc ---
class ReceiptCaptureBloc extends Bloc<ReceiptCaptureEvent, ReceiptCaptureState> {
  final ReceiptRepository _receiptRepository;

  ReceiptCaptureBloc(this._receiptRepository) : super(const ReceiptCaptureInitial()) {
    on<SelectTransactionType>((event, emit) {
      emit(ReceiptCaptureTypeSelected(event.type));
    });

    on<CaptureReceiptImage>((event, emit) async {
      if (state.transactionType == null) return;
      
      String finalPath = event.localPath;
      try {
        final tempDir = await getTemporaryDirectory();
        final targetPath = '${tempDir.path}/comp_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          event.localPath,
          targetPath,
          quality: 70,
          minWidth: 1024,
          minHeight: 1024,
        );
        
        if (compressedFile != null) {
          finalPath = compressedFile.path;
        }
      } catch (e) {
        // Fallback to original if compression fails
      }

      emit(ReceiptCaptureImagePicked(state.transactionType!, finalPath));
    });

    on<UploadReceipt>((event, emit) async {
      if (state.transactionType == null || state.localPath == null) return;
      
      final type = state.transactionType!;
      final path = state.localPath!;
      
      emit(ReceiptCaptureLoading(type, path));
      
      try {
        final storagePath = await _receiptRepository.uploadReceipt(
          localPath: path,
          businessId: event.businessId,
          transactionType: type,
        ).timeout(const Duration(seconds: 15));
        emit(ReceiptCaptureSuccess(type, path, storagePath));
      } on TimeoutException {
        emit(ReceiptCaptureFailure(type, path, 'Network timeout. Please check your connection.'));
      } on SocketException {
        emit(ReceiptCaptureFailure(type, path, 'Network error. Please check your connection.'));
      } catch (e) {
        emit(ReceiptCaptureFailure(type, path, e.toString()));
      }
    });
  }
}
