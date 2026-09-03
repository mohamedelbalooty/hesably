import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/receipt_repository_impl.dart';
import '../bloc/receipt_capture_bloc.dart';

class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

  String get _currentBusinessId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'unknown-business';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('capture.title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<ReceiptCaptureBloc, ReceiptCaptureState>(
        listener: (context, state) {
          if (state is ReceiptCaptureSuccess) {
            HapticFeedback.mediumImpact();
            context.push('/review-edit', extra: {
              'storagePath': state.storagePath,
              'businessId': _currentBusinessId,
            });
          } else if (state is ReceiptCaptureFailure) {
            HapticFeedback.vibrate();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: AppTheme.expense,
                action: SnackBarAction(
                  label: 'transactions.manual_entry'.tr(),
                  textColor: Colors.white,
                  onPressed: () {
                    context.push('/transaction-form', extra: {
                      'type': state.transactionType ?? 'expense',
                      'businessId': _currentBusinessId,
                    });
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ReceiptCaptureInitial) {
            return _buildTypeSelector(context);
          } else if (state is ReceiptCaptureTypeSelected) {
            return _buildImagePickerOptions(context, state.transactionType ?? 'expense');
          } else if (state is ReceiptCaptureLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 20),
                  Text(
                    'capture.uploading'.tr(),
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          } else if (state is ReceiptCaptureImagePicked ||
              (state is ReceiptCaptureFailure && state.localPath != null)) {
            return _buildUploadConfirmation(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'capture.type_question'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
          ),
          const SizedBox(height: 32),

          // Sale / Income Card
          _TypeSelectionCard(
            title: 'capture.sale_income'.tr(),
            description: 'capture.sale_income_desc'.tr(),
            icon: Icons.trending_up_rounded,
            color: AppTheme.income,
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<ReceiptCaptureBloc>().add(const SelectTransactionType('income'));
            },
          ),
          const SizedBox(height: 16),

          // Purchase / Expense Card
          _TypeSelectionCard(
            title: 'capture.purchase_expense'.tr(),
            description: 'capture.purchase_expense_desc'.tr(),
            icon: Icons.trending_down_rounded,
            color: AppTheme.primary,
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<ReceiptCaptureBloc>().add(const SelectTransactionType('expense'));
            },
          ),
          const SizedBox(height: 48),

          // Manual entry bypass
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: Text(
                'capture.enter_manually'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  decoration: TextDecoration.underline,
                ),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push('/transaction-form', extra: {
                  'businessId': _currentBusinessId,
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerOptions(BuildContext context, String transactionType) {
    return Column(
      children: [
        // Camera Viewfinder Simulation Frame
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.surfaceLight, width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Corner brackets
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.primary, width: 3),
                        left: BorderSide(color: AppTheme.primary, width: 3),
                      ),
                    )),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.primary, width: 3),
                        right: BorderSide(color: AppTheme.primary, width: 3),
                      ),
                    )),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.primary, width: 3),
                        left: BorderSide(color: AppTheme.primary, width: 3),
                      ),
                    )),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.primary, width: 3),
                        right: BorderSide(color: AppTheme.primary, width: 3),
                      ),
                    )),
                  ),

                  // Center Guidance
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.document_scanner_rounded,
                        size: 64,
                        color: AppTheme.primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          'capture.align_hint'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom Capture Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Choose from Gallery
                  IconButton.filledTonal(
                    iconSize: 28,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.surfaceLight,
                      padding: const EdgeInsets.all(14),
                    ),
                    icon: const Icon(Icons.photo_library_rounded, color: AppTheme.text),
                    tooltip: 'capture.choose_gallery'.tr(),
                    onPressed: () => _pickImage(context, ImageSource.gallery),
                  ),

                  // Main Camera Shutter Button
                  InkWell(
                    onTap: () => _pickImage(context, ImageSource.camera),
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary, width: 3),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: AppTheme.background,
                          size: 36,
                        ),
                      ),
                    ),
                  ),

                  // Manual Entry Bypass Button
                  IconButton.filledTonal(
                    iconSize: 28,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.surfaceLight,
                      padding: const EdgeInsets.all(14),
                    ),
                    icon: const Icon(Icons.edit_note_rounded, color: AppTheme.text),
                    tooltip: 'capture.enter_manually'.tr(),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.push('/transaction-form', extra: {
                        'businessId': _currentBusinessId,
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'capture.take_photo'.tr(),
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      HapticFeedback.lightImpact();
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 70,
      );
      if (image != null && context.mounted) {
        HapticFeedback.selectionClick();
        context.read<ReceiptCaptureBloc>().add(CaptureReceiptImage(image.path));
      }
    } catch (e) {
      if (context.mounted) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppTheme.expense,
          ),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(state.localPath!),
                cacheWidth: 800,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.read<ReceiptCaptureBloc>().add(const ResetReceiptCapture());
                  },
                  child: Text('capture.retake'.tr()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.read<ReceiptCaptureBloc>().add(UploadReceipt(_currentBusinessId));
                  },
                  child: Text('capture.use_photo'.tr()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeSelectionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TypeSelectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.text,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
