import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/transaction_list_bloc.dart';

class TransactionsPage extends StatefulWidget {
  final String businessId;

  const TransactionsPage({super.key, required this.businessId});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TransactionListBloc>().add(LoadTransactions(widget.businessId));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<TransactionListBloc>().add(LoadMoreTransactions());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _onSearchChanged(String query) {
    final currentState = context.read<TransactionListBloc>().state;
    context.read<TransactionListBloc>().add(FilterTransactions(
      type: currentState.type,
      categoryId: currentState.categoryId,
      startDate: currentState.startDate,
      endDate: currentState.endDate,
      searchQuery: query,
    ));
  }

  void _onTypeFilterChanged(String? type) {
    HapticFeedback.selectionClick();
    final currentState = context.read<TransactionListBloc>().state;
    context.read<TransactionListBloc>().add(FilterTransactions(
      type: type,
      categoryId: currentState.categoryId,
      startDate: currentState.startDate,
      endDate: currentState.endDate,
      searchQuery: currentState.searchQuery,
    ));
  }

  Future<void> _navigateAndRefresh(String path, {Object? extra}) async {
    final result = await context.push(path, extra: extra);
    if (result == true && mounted) {
      context.read<TransactionListBloc>().add(LoadTransactions(widget.businessId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('transactions.title'.tr()),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: const BoxDecoration(
              color: AppTheme.background,
            ),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'transactions.search_hint'.tr(),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),

                // Quick Filter Chips (All, Income, Expense)
                BlocBuilder<TransactionListBloc, TransactionListState>(
                  builder: (context, state) {
                    final selectedType = state.type;
                    return Row(
                      children: [
                        _buildFilterChip(
                          label: 'transactions.filter_all'.tr(),
                          isSelected: selectedType == null,
                          onTap: () => _onTypeFilterChanged(null),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'transactions.filter_income'.tr(),
                          isSelected: selectedType == 'income',
                          color: AppTheme.income,
                          icon: Icons.arrow_downward_rounded,
                          onTap: () => _onTypeFilterChanged('income'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'transactions.filter_expense'.tr(),
                          isSelected: selectedType == 'expense',
                          color: AppTheme.expense,
                          icon: Icons.arrow_upward_rounded,
                          onTap: () => _onTypeFilterChanged('expense'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Transaction List or Empty State
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              onRefresh: () async {
                context.read<TransactionListBloc>().add(LoadTransactions(widget.businessId));
              },
              child: BlocBuilder<TransactionListBloc, TransactionListState>(
                builder: (context, state) {
                  if (state is TransactionListInitial ||
                      (state is TransactionListLoading && state.transactions.isEmpty)) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                  }

                  if (state is TransactionListError && state.transactions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Error: ${state.error}',
                          style: const TextStyle(color: AppTheme.expense),
                        ),
                      ),
                    );
                  }

                  if (state.transactions.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                      children: [
                        const SizedBox(height: 40),
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.surfaceLight),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              size: 40,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'transactions.empty_title'.tr(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.text,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'transactions.empty_desc'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded),
                            label: Text('transactions.add_button'.tr()),
                            onPressed: () => context.push('/capture'),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: state.hasReachedMax
                        ? state.transactions.length
                        : state.transactions.length + 1,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index >= state.transactions.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(color: AppTheme.primary),
                          ),
                        );
                      }

                      final tx = state.transactions[index];
                      final isIncome = tx.type == 'income';
                      final dateStr = tx.date.toLocal().toString().split(' ')[0];

                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.surfaceLight),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? AppTheme.income.withValues(alpha: 0.15)
                                  : AppTheme.expense.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isIncome ? AppTheme.income : AppTheme.expense,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            tx.vendorCustomerName ?? 'common.unknown'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.text,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 13,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                if (tx.receiptImagePath != null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.attachment_rounded,
                                    size: 14,
                                    color: AppTheme.primary,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          trailing: Text(
                            '${isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)} ج.م',
                            style: TextStyle(
                              color: isIncome ? AppTheme.income : AppTheme.expense,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _navigateAndRefresh(
                              '/transaction-form',
                              extra: {
                                'businessId': widget.businessId,
                                'transaction': tx,
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          context.push('/capture');
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.background,
        child: const Icon(Icons.add_a_photo_rounded),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? color,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? AppTheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withValues(alpha: 0.15) : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppTheme.surfaceLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? chipColor : AppTheme.textMuted),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.text : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
