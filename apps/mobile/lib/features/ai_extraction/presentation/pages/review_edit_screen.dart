import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/ai_extraction_repository_impl.dart';
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
      child: const ReviewEditView(),
    );
  }
}

class ReviewEditView extends StatefulWidget {
  const ReviewEditView({super.key});

  @override
  State<ReviewEditView> createState() => _ReviewEditViewState();
}

class _ReviewEditViewState extends State<ReviewEditView> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _vendorController = TextEditingController();
  final _categoryController = TextEditingController();

  String _transactionType = 'expense';

  void _populateForm(draft) {
    _transactionType = draft.transactionType;
    _amountController.text = draft.totalAmount?.toString() ?? '';
    _dateController.text = draft.date ?? '';
    _vendorController.text = draft.vendorCustomerName ?? '';
    _categoryController.text = draft.suggestedCategory ?? '';
  }

  Color _getConfidenceColor(double score) {
    if (score >= 0.85) return Colors.transparent;
    if (score >= 0.50) return Colors.orange.withValues(alpha: 0.2);
    return Colors.red.withValues(alpha: 0.2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _vendorController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Edit'),
      ),
      body: BlocConsumer<AiExtractionBloc, AiExtractionState>(
        listener: (context, state) {
          if (state is AiExtractionSuccess) {
            if (!state.draft.isReceipt) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Couldn't read this as a receipt. Please try again or enter manually.")),
               );
            } else {
               _populateForm(state.draft);
            }
          }
        },
        builder: (context, state) {
          if (state is AiExtractionInitial || state is AiExtractionLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing receipt with AI...'),
                ],
              ),
            );
          } else if (state is AiExtractionFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Extraction failed: ${state.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Fallback to manual entry
                        // For MVP, just show empty form or navigate to manual entry screen
                        setState(() {}); // Transition to manual form if implemented
                      },
                      child: const Text('Enter manually instead'),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is AiExtractionSuccess) {
            if (!state.draft.isReceipt) {
               return Center(
                 child: ElevatedButton(
                   onPressed: () {
                     // Fallback to manual
                   },
                   child: const Text('Enter manually instead'),
                 ),
               );
            }
            return _buildForm(context, state.draft.confidenceScores);
          }
          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: BlocBuilder<AiExtractionBloc, AiExtractionState>(
        builder: (context, state) {
          if (state is AiExtractionSuccess && state.draft.isReceipt) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                     // Sprint 4: Save to transactions table
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Transaction confirmed! (Saving logic in Sprint 4)')),
                     );
                     context.go('/');
                  }
                },
                child: const Text('Confirm & Save'),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, confidenceScores) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _transactionType,
              items: const [
                DropdownMenuItem(value: 'expense', child: Text('Purchase / Expense')),
                DropdownMenuItem(value: 'income', child: Text('Sale / Income')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _transactionType = val);
              },
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 16),
            Container(
              color: _getConfidenceColor(confidenceScores.totalAmount),
              child: TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Total Amount (EGP)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              color: _getConfidenceColor(confidenceScores.date),
              child: TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              color: _getConfidenceColor(confidenceScores.vendorCustomerName),
              child: TextFormField(
                controller: _vendorController,
                decoration: const InputDecoration(labelText: 'Vendor / Customer Name'),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 24),
            const Text('Red/Orange highlights indicate low AI confidence. Please verify.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
