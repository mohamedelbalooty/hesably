import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesably_mobile/features/transactions/domain/models/transaction.dart';
import 'package:hesably_mobile/features/transactions/presentation/bloc/transaction_form_bloc.dart';
import 'package:hesably_mobile/features/categories/presentation/bloc/category_management_bloc.dart';

class TransactionFormPage extends StatefulWidget {
  final Transaction? initialTransaction;
  final String businessId;

  const TransactionFormPage({
    super.key,
    this.initialTransaction,
    required this.businessId,
  });

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  late double _amount;
  late DateTime _date;
  String? _categoryId;
  String? _vendorName;
  
  bool get _isEdit => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    _type = widget.initialTransaction?.type ?? 'expense';
    _amount = widget.initialTransaction?.amount ?? 0.0;
    _date = widget.initialTransaction?.date ?? DateTime.now();
    _categoryId = widget.initialTransaction?.categoryId;
    _vendorName = widget.initialTransaction?.vendorCustomerName;

    // Load active categories for the dropdown
    context.read<CategoryManagementBloc>().add(LoadCategories(widget.businessId));
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final tx = Transaction(
        id: widget.initialTransaction?.id ?? '',
        businessId: widget.businessId,
        type: _type,
        amount: _amount,
        date: _date,
        categoryId: _categoryId ?? '',
        vendorCustomerName: _vendorName,
        createdAt: widget.initialTransaction?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      context.read<TransactionFormBloc>().add(SaveTransaction(tx, isEdit: _isEdit));
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TransactionFormBloc>().add(DeleteTransaction(widget.initialTransaction!.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Transaction' : 'New Transaction'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<TransactionFormBloc, TransactionFormState>(
            listener: (context, state) {
              if (state is TransactionFormSuccess || state is TransactionFormDeleteSuccess) {
                Navigator.pop(context, true); // True to indicate success/refresh needed
              } else if (state is TransactionFormFailure) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error)));
              }
            },
          ),
        ],
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: const [
                  DropdownMenuItem(value: 'expense', child: Text('Expense')),
                  DropdownMenuItem(value: 'income', child: Text('Income')),
                ],
                onChanged: (val) => setState(() => _type = val!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _amount == 0.0 ? '' : _amount.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Invalid number';
                  return null;
                },
                onSaved: (val) => _amount = double.parse(val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _vendorName,
                decoration: const InputDecoration(labelText: 'Vendor/Customer Name'),
                onSaved: (val) {
                  _vendorName = val != null && val.trim().isNotEmpty ? val.trim() : null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text('${_date.toLocal()}'.split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              BlocBuilder<CategoryManagementBloc, CategoryManagementState>(
                builder: (context, state) {
                  if (state is CategoryManagementLoading || state is CategoryManagementInitial) {
                    return const CircularProgressIndicator();
                  } else if (state is CategoryManagementLoaded) {
                    // Filter out hidden categories unless it's the currently selected one
                    final activeCategories = state.categories.where((c) => !c.isHidden || c.id == _categoryId).toList();
                    
                    if (_categoryId == null && activeCategories.isNotEmpty) {
                      _categoryId = activeCategories.first.id;
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _categoryId,
                      items: activeCategories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _categoryId = val),
                      decoration: const InputDecoration(labelText: 'Category'),
                      validator: (val) => val == null ? 'Required' : null,
                    );
                  } else if (state is CategoryManagementError) {
                    return Text('Error loading categories: ${state.error}');
                  }
                  return const SizedBox();
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
