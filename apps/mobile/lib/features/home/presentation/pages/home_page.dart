import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../transactions/presentation/pages/transactions_page.dart';
import '../../../reports/presentation/pages/reports_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../transactions/presentation/bloc/transaction_list_bloc.dart';
import '../../../reports/presentation/bloc/reports_bloc.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../../reports/domain/repositories/report_repository.dart';
import '../../../businesses/domain/repositories/business_repository.dart';
import '../../../../core/di/injection.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String? _businessId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessId();
  }

  Future<void> _loadBusinessId() async {
    final supabase = getIt<SupabaseClient>();
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      final business = await getIt<BusinessRepository>().getBusinessForUser(userId);
      if (mounted) {
        setState(() {
          _businessId = business?.id;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_businessId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No business found. Please complete onboarding.'),
              ElevatedButton(
                onPressed: () => context.go('/onboarding'),
                child: const Text('Go to Onboarding'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildTransactionsTab(),
          _buildReportsTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                context.push('/capture');
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildTransactionsTab() {
    return BlocProvider(
      create: (_) => TransactionListBloc(getIt<TransactionRepository>()),
      child: TransactionsPage(businessId: _businessId!),
    );
  }

  Widget _buildReportsTab() {
    return BlocProvider(
      create: (_) => ReportsBloc(reportRepository: getIt<ReportRepository>())
        ..add(LoadReport(businessId: _businessId!)),
      child: ReportsPage(businessId: _businessId!),
    );
  }

  Widget _buildSettingsTab() {
    return BlocProvider(
      create: (_) => SettingsBloc(
        businessRepository: getIt<BusinessRepository>(),
        supabase: getIt<SupabaseClient>(),
      )..add(LoadSettings(getIt<SupabaseClient>().auth.currentUser?.id ?? '')),
      child: SettingsPage(businessId: _businessId!),
    );
  }
}
