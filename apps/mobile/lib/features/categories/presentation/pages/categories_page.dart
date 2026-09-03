import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesably_mobile/features/categories/presentation/bloc/category_management_bloc.dart';
import 'package:hesably_mobile/features/transactions/domain/models/category.dart';

class CategoriesPage extends StatefulWidget {
  final String businessId;

  const CategoriesPage({super.key, required this.businessId});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryManagementBloc>().add(LoadCategories(widget.businessId));
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  context.read<CategoryManagementBloc>().add(AddCustomCategory(widget.businessId, controller.text.trim()));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(Category category, List<Category> allCategories) {
    String? selectedReassignId;
    final availableCategories = allCategories.where((c) => c.id != category.id).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Are you sure you want to delete this category?'),
                  const SizedBox(height: 16),
                  const Text('If this category is used in transactions, you must reassign them to another category:'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReassignId,
                    hint: const Text('Select replacement'),
                    items: availableCategories.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedReassignId = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    context.read<CategoryManagementBloc>().add(
                      DeleteCustomCategory(
                        category.id, 
                        reassignToCategoryId: selectedReassignId,
                      )
                    );
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: BlocConsumer<CategoryManagementBloc, CategoryManagementState>(
        listener: (context, state) {
          if (state is CategoryManagementError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error)));
          }
        },
        builder: (context, state) {
          if (state is CategoryManagementLoading || state is CategoryManagementInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CategoryManagementLoaded) {
            if (state.categories.isEmpty) {
              return const Center(child: Text('No categories found.'));
            }
            return ListView.builder(
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return ListTile(
                  title: Text(category.name),
                  subtitle: Text(category.isDefault ? 'Default' : 'Custom'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (category.isDefault)
                        IconButton(
                          icon: Icon(category.isHidden ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            context.read<CategoryManagementBloc>().add(ToggleCategoryVisibility(category.id, !category.isHidden));
                          },
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(category, state.categories),
                        ),
                    ],
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
