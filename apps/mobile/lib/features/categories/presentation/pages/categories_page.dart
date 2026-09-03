import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../transactions/domain/models/category.dart';
import '../bloc/category_management_bloc.dart';

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

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('util') || lower.contains('كهربا') || lower.contains('مرافق')) {
      return Icons.bolt_rounded;
    }
    if (lower.contains('rent') || lower.contains('إيجار')) {
      return Icons.apartment_rounded;
    }
    if (lower.contains('salar') || lower.contains('راتب') || lower.contains('مرتب')) {
      return Icons.people_alt_rounded;
    }
    if (lower.contains('trans') || lower.contains('نقل') || lower.contains('شحن')) {
      return Icons.local_shipping_rounded;
    }
    if (lower.contains('stock') || lower.contains('بضاعة') || lower.contains('مشتريات')) {
      return Icons.inventory_2_rounded;
    }
    if (lower.contains('sale') || lower.contains('مبيعات')) {
      return Icons.point_of_sale_rounded;
    }
    return Icons.category_rounded;
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('categories.add_title'.tr()),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'categories.name_label'.tr(),
              prefixIcon: const Icon(Icons.label_outline_rounded, color: AppTheme.primary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dContext),
              child: Text('common.cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  HapticFeedback.lightImpact();
                  context.read<CategoryManagementBloc>().add(
                        AddCustomCategory(widget.businessId, controller.text.trim()),
                      );
                  Navigator.pop(dContext);
                }
              },
              child: Text('common.save'.tr()),
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
      builder: (dContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: Text('categories.delete_confirm'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'categories.reassign_hint'.tr(),
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReassignId,
                    hint: Text('common.unknown'.tr()),
                    items: availableCategories.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => selectedReassignId = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dContext),
                  child: Text('common.cancel'.tr()),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expense),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.read<CategoryManagementBloc>().add(
                          DeleteCustomCategory(
                            category.id,
                            reassignToCategoryId: selectedReassignId,
                          ),
                        );
                    Navigator.pop(dContext);
                  },
                  child: Text('common.delete'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('categories.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'categories.add_title'.tr(),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: BlocConsumer<CategoryManagementBloc, CategoryManagementState>(
        listener: (context, state) {
          if (state is CategoryManagementError) {
            HapticFeedback.vibrate();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppTheme.expense),
            );
          }
        },
        builder: (context, state) {
          if (state is CategoryManagementLoading || state is CategoryManagementInitial) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (state is CategoryManagementLoaded) {
            if (state.categories.isEmpty) {
              return Center(
                child: Text(
                  'transactions.empty_title'.tr(),
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: state.categories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final category = state.categories[index];
                final icon = _getCategoryIcon(category.name);

                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.surfaceLight),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: AppTheme.primary, size: 22),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppTheme.text,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: category.isDefault
                                ? AppTheme.surfaceLight
                                : AppTheme.cta.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category.isDefault
                                ? 'categories.default_badge'.tr()
                                : 'categories.custom_badge'.tr(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: category.isDefault ? AppTheme.textMuted : AppTheme.cta,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (category.isDefault)
                          IconButton(
                            icon: Icon(
                              category.isHidden
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: category.isHidden ? AppTheme.textMuted : AppTheme.primary,
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              context.read<CategoryManagementBloc>().add(
                                    ToggleCategoryVisibility(category.id, !category.isHidden),
                                  );
                            },
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.expense),
                            onPressed: () => _confirmDelete(category, state.categories),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.background,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
