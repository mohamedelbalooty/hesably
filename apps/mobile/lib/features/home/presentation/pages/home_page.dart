import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
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
import '../../../../core/theme/app_theme.dart';

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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_businessId == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_rounded, size: 56, color: AppTheme.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  'onboarding.welcome_title'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'onboarding.welcome_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => context.go('/onboarding'),
                  child: Text('onboarding.start_button'.tr()),
                ),
              ],
            ),
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.surfaceLight, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            HapticFeedback.selectionClick();
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_rounded),
              activeIcon: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary),
              label: 'transactions.title'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_rounded),
              activeIcon: const Icon(Icons.bar_chart_rounded, color: AppTheme.primary),
              label: 'reports.title'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings_rounded, color: AppTheme.primary),
              label: 'settings.title'.tr(),
            ),
          ],
        ),
      ),
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
