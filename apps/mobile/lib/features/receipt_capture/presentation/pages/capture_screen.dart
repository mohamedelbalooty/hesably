import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/receipt_repository_impl.dart';
import '../bloc/receipt_capture_bloc.dart';
import 'dart:io';

class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app, inject this via get_it or similar provider
    return BlocProvider(
      create: (context) => ReceiptCaptureBloc(
        ReceiptRepositoryImpl(Supabase.instance.client),
      ),
      child: const CaptureView(),
    );
  }
}

class CaptureView extends StatefulWidget {
  const CaptureView({super.key});

  @override
  State<CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<CaptureView> {
  final ImagePicker _picker = ImagePicker();
  
  // Note: For MVP we hardcode a business ID or fetch from Auth/SharedPrefs.
  // Assuming business logic will provide the active business ID.
  // Using user's id as a fallback placeholder for now if business ID isn't directly available.
  String get _currentBusinessId => Supabase.instance.client.auth.currentUser?.id ?? 'unknown-business';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<ReceiptCaptureBloc, ReceiptCaptureState>(
        listener: (context, state) {
          if (state is ReceiptCaptureSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Receipt uploaded successfully!')),
            );
            // In Sprint 3, this would route to Review & Edit screen with the storagePath
            context.push('/review-edit', extra: {
              'storagePath': state.storagePath,
              'businessId': _currentBusinessId,
            });
          } else if (state is ReceiptCaptureFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: ${state.error}')),
            );
          }
        },
        builder: (context, state) {
          if (state is ReceiptCaptureInitial) {
            return _buildTypeSelector(context);
          } else if (state is ReceiptCaptureTypeSelected) {
            return _buildImagePickerOptions(context);
          } else if (state is ReceiptCaptureLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing receipt...'),
                ],
              ),
            );
          } else if (state is ReceiptCaptureImagePicked || state is ReceiptCaptureFailure) {
            return _buildUploadConfirmation(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Is this a Sale or Purchase?', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => context.read<ReceiptCaptureBloc>().add(const SelectTransactionType('income')),
                child: const Text('Sale / Income'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => context.read<ReceiptCaptureBloc>().add(const SelectTransactionType('expense')),
                child: const Text('Purchase / Expense'),
              ),
            ],
          ),
          const SizedBox(height: 48),
          TextButton(
            onPressed: () {
              // Manual entry bypass
              context.pop();
              // Navigate to manual entry screen (Sprint 4)
            },
            child: const Text('Skip — enter manually'),
          )
        ],
      ),
    );
  }

  Widget _buildImagePickerOptions(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take a Photo'),
            onPressed: () => _pickImage(context, ImageSource.camera),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text('Choose from Gallery'),
            onPressed: () => _pickImage(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null && context.mounted) {
        context.read<ReceiptCaptureBloc>().add(CaptureReceiptImage(image.path));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Widget _buildUploadConfirmation(BuildContext context, ReceiptCaptureState state) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.file(
              File(state.localPath!),
              cacheWidth: 800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: () {
              context.read<ReceiptCaptureBloc>().add(UploadReceipt(_currentBusinessId));
            },
            child: const Text('Upload Receipt'),
          ),
        )
      ],
    );
  }
}
