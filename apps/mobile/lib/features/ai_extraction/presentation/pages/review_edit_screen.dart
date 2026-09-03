import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../../transactions/domain/models/category.dart';
import '../../../transactions/domain/models/transaction.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../data/repositories/ai_extraction_repository_impl.dart';
import '../../domain/models/ai_extraction_draft.dart';
import '../bloc/ai_extraction_bloc.dart';

class ReviewEditScreen extends StatelessWidget {
  final String storagePath;
  final String businessId;

  const ReviewEditScreen({
    super.key,
    required this.storagePath,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AiExtractionBloc(
        AiExtractionRepositoryImpl(Supabase.instance.client),
      )..add(StartExtraction(businessId: businessId, receiptImagePath: storagePath)),
      child: ReviewEditView(storagePath: storagePath, businessId: businessId),
    );
  }
}

class ReviewEditView extends StatefulWidget {
  final String storagePath;
  final String businessId;

  const ReviewEditView({
    super.key,
    required this.storagePath,
    required this.businessId,
  });

  @override
  State<ReviewEditView> createState() => _ReviewEditViewState();
}

class _ReviewEditViewState extends State<ReviewEditView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _vendorController = TextEditingController();

  String _transactionType = 'expense';
  String? _selectedCategoryId;
  List<Category> _categories = [];
  bool _isSaving = false;
  ConfidenceScores? _confidenceScores;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await getIt<CategoryRepository>().getActiveCategories(widget.businessId);
      if (mounted) {
        setState(() {
          _categories = cats;
          if (_selectedCategoryId == null && cats.isNotEmpty) {
            _selectedCategoryId = cats.first.id;
          }
        });
      }
    } catch (_) {}
  }

  void _populateForm(AiExtractionDraft draft) {
    _transactionType = draft.transactionType;
    _amountController.text = draft.totalAmount != null ? draft.totalAmount!.toStringAsFixed(2) : '';
    _dateController.text = draft.date ?? DateTime.now().toIso8601String().split('T')[0];
    _vendorController.text = draft.vendorCustomerName ?? '';
    _confidenceScores = draft.confidenceScores;

    if (draft.suggestedCategory != null && _categories.isNotEmpty) {
      final match = _categories.firstWhere(
        (c) => c.name.toLowerCase().contains(draft.suggestedCategory!.toLowerCase()),
        orElse: () => _categories.first,
      );
      _selectedCategoryId = match.id;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
      final date = DateTime.tryParse(_dateController.text.trim()) ?? DateTime.now();

      final newTx = Transaction(
        id: const Uuid().v4(),
        businessId: widget.businessId,
        type: _transactionType,
        amount: amount,
        date: date,
        categoryId: _selectedCategoryId ?? (_categories.isNotEmpty ? _categories.first.id : 'default'),
        vendorCustomerName: _vendorController.text.trim().isNotEmpty ? _vendorController.text.trim() : null,
        receiptImagePath: widget.storagePath.isNotEmpty ? widget.storagePath : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await getIt<TransactionRepository>().createTransaction(newTx);

      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.success'.tr()),
            backgroundColor: AppTheme.income,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.expense,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('review.title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<AiExtractionBloc, AiExtractionState>(
        listener: (context, state) {
          if (state is AiExtractionSuccess) {
            if (state.draft.isReceipt) {
              _populateForm(state.draft);
            }
          }
        },
        builder: (context, state) {
          if (state is AiExtractionInitial || state is AiExtractionLoading) {
            return _AiScanningWaitView(
              onManualBypass: () {
                HapticFeedback.selectionClick();
                context.pushReplacement('/transaction-form', extra: {
                  'businessId': widget.businessId,
                });
              },
            );
          } else if (state is AiExtractionFailure) {
            return _buildErrorState(context, state.error);
          } else if (state is AiExtractionSuccess) {
            if (!state.draft.isReceipt) {
              return _buildErrorState(context, 'ai.extraction_failed_desc'.tr());
            }
            return _buildForm(context);
          }
          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: BlocBuilder<AiExtractionBloc, AiExtractionState>(
        builder: (context, state) {
          if (state is AiExtractionSuccess && state.draft.isReceipt) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTransaction,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.background),
                      )
                    : Text('review.confirm_button'.tr()),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.expense.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 56, color: AppTheme.expense),
            ),
            const SizedBox(height: 20),
            Text(
              'ai.extraction_failed'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'ai.extraction_failed_desc'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text('common.retry'.tr()),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.read<AiExtractionBloc>().add(
                        StartExtraction(
                          businessId: widget.businessId,
                          receiptImagePath: widget.storagePath,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text('ai.manual_fallback'.tr()),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.pushReplacement('/transaction-form', extra: {
                        'businessId': widget.businessId,
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final hasLowConfidence = _confidenceScores != null &&
        (_confidenceScores!.totalAmount < 0.70 ||
            _confidenceScores!.date < 0.70 ||
            _confidenceScores!.vendorCustomerName < 0.70);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notice banner if low confidence
            if (hasLowConfidence) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppTheme.warning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'review.low_confidence_hint'.tr(),
                        style: const TextStyle(color: AppTheme.warning, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Transaction Type Segmented Toggle
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'expense',
                  label: Text('capture.purchase_expense'.tr()),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
                ButtonSegment(
                  value: 'income',
                  label: Text('capture.sale_income'.tr()),
                  icon: const Icon(Icons.arrow_downward_rounded),
                ),
              ],
              selected: {_transactionType},
              onSelectionChanged: (set) {
                HapticFeedback.selectionClick();
                setState(() => _transactionType = set.first);
              },
            ),
            const SizedBox(height: 24),

            // Total Amount Field
            _buildFieldContainer(
              isLowConfidence: _confidenceScores != null && _confidenceScores!.totalAmount < 0.70,
              child: TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
                decoration: InputDecoration(
                  labelText: 'review.amount_label'.tr(),
                  prefixIcon: const Icon(Icons.attach_money_rounded, color: AppTheme.primary),
                  suffixText: 'EGP',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'الحقل مطلوب'.tr();
                  if (double.tryParse(val.trim()) == null) return 'قيمة غير صالحة'.tr();
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Date Field
            _buildFieldContainer(
              isLowConfidence: _confidenceScores != null && _confidenceScores!.date < 0.70,
              child: TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _dateController.text = picked.toIso8601String().split('T')[0];
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'review.date_label'.tr(),
                  prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppTheme.primary),
                ),
                validator: (val) => val == null || val.isEmpty ? 'الحقل مطلوب'.tr() : null,
              ),
            ),
            const SizedBox(height: 16),

            // Vendor / Customer Field
            _buildFieldContainer(
              isLowConfidence: _confidenceScores != null && _confidenceScores!.vendorCustomerName < 0.70,
              child: TextFormField(
                controller: _vendorController,
                decoration: InputDecoration(
                  labelText: 'review.vendor_label'.tr(),
                  prefixIcon: const Icon(Icons.storefront_rounded, color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category Selector
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              items: _categories.map((c) {
                return DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategoryId = val);
                }
              },
              decoration: InputDecoration(
                labelText: 'review.category_label'.tr(),
                prefixIcon: const Icon(Icons.category_rounded, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldContainer({required bool isLowConfidence, required Widget child}) {
    if (!isLowConfidence) return child;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning, width: 1.5),
      ),
      child: child,
    );
  }
}

/// Dynamic Progressive AI Scanner Wait State
class _AiScanningWaitView extends StatefulWidget {
  final VoidCallback onManualBypass;

  const _AiScanningWaitView({required this.onManualBypass});

  @override
  State<_AiScanningWaitView> createState() => _AiScanningWaitViewState();
}

class _AiScanningWaitViewState extends State<_AiScanningWaitView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _currentStepIndex = 0;
  Timer? _stepTimer;

  final List<String> _steps = [
    'ai.step_uploading',
    'ai.step_analyzing',
    'ai.step_categorizing',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _stepTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (mounted) {
        setState(() {
          _currentStepIndex = (_currentStepIndex + 1) % _steps.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Scanning Visual Box
            Container(
              width: 160,
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceLight, width: 2),
              ),
              child: Stack(
                children: [
                  // Receipt mock lines
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 10, width: 60, color: AppTheme.surfaceLight),
                        const SizedBox(height: 14),
                        Container(height: 6, width: 100, color: AppTheme.surfaceLight.withValues(alpha: 0.6)),
                        const SizedBox(height: 8),
                        Container(height: 6, width: 80, color: AppTheme.surfaceLight.withValues(alpha: 0.6)),
                        const SizedBox(height: 8),
                        Container(height: 6, width: 110, color: AppTheme.surfaceLight.withValues(alpha: 0.6)),
                        const Spacer(),
                        Container(height: 10, width: 80, color: AppTheme.primary.withValues(alpha: 0.5)),
                      ],
                    ),
                  ),

                  // Animated Scanning Laser Line
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Positioned(
                        top: 20 + (_animController.value * 140),
                        left: 12,
                        right: 12,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Title
            Text(
              'ai.processing_title'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
            ),
            const SizedBox(height: 12),

            // Rotating Step Message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _steps[_currentStepIndex].tr(),
                key: ValueKey<int>(_currentStepIndex),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Manual fallback button
            TextButton.icon(
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: Text('ai.manual_fallback'.tr()),
              onPressed: widget.onManualBypass,
            ),
          ],
        ),
      ),
    );
  }
}
