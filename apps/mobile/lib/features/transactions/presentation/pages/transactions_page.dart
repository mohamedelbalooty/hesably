import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:hesably_mobile/features/transactions/presentation/bloc/transaction_list_bloc.dart';

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

  void _openFilters() {
    final currentState = context.read<TransactionListBloc>().state;
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All Types'),
                trailing: currentState.type == null ? const Icon(Icons.check) : null,
                onTap: () {
                  context.read<TransactionListBloc>().add(FilterTransactions(
                    searchQuery: currentState.searchQuery,
                  ));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Income'),
                trailing: currentState.type == 'income' ? const Icon(Icons.check) : null,
                onTap: () {
                  context.read<TransactionListBloc>().add(FilterTransactions(
                    type: 'income',
                    searchQuery: currentState.searchQuery,
                  ));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Expense'),
                trailing: currentState.type == 'expense' ? const Icon(Icons.check) : null,
                onTap: () {
                  context.read<TransactionListBloc>().add(FilterTransactions(
                    type: 'expense',
                    searchQuery: currentState.searchQuery,
                  ));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _navigateAndRefresh(String path, {Object? extra}) async {
    final result = await context.push(path, extra: extra);
    if (result == true) {
      if (mounted) {
        context.read<TransactionListBloc>().add(LoadTransactions(widget.businessId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by vendor or customer...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilters,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<TransactionListBloc>().add(LoadTransactions(widget.businessId));
        },
        child: BlocBuilder<TransactionListBloc, TransactionListState>(
          builder: (context, state) {
            if (state is TransactionListInitial || 
                (state is TransactionListLoading && state.transactions.isEmpty)) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is TransactionListError && state.transactions.isEmpty) {
              return Center(child: Text('Error: ${state.error}'));
            }
            
            if (state.transactions.isEmpty) {
              return ListView( // ListView allows RefreshIndicator to work even when empty
                children: const [
                   SizedBox(height: 200),
                   Center(child: Text('No transactions found.')),
                ],
              );
            }

            return ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.hasReachedMax ? state.transactions.length : state.transactions.length + 1,
              itemBuilder: (context, index) {
                if (index >= state.transactions.length) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                
                final tx = state.transactions[index];
                return ListTile(
                  title: Text(tx.vendorCustomerName ?? 'Unknown Vendor'),
                  subtitle: Text('${tx.type} - ${tx.date.toLocal().toString().split(' ')[0]}'),
                  trailing: Text(
                    '${tx.type == 'income' ? '+' : '-'}${tx.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: tx.type == 'income' ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    _navigateAndRefresh(
                      '/transaction-form',
                      extra: {
                        'businessId': widget.businessId,
                        'transaction': tx,
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateAndRefresh(
            '/transaction-form',
            extra: {
              'businessId': widget.businessId,
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
