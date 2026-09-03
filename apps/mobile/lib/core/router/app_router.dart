import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/businesses/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/receipt_capture/presentation/pages/capture_screen.dart';
import '../../features/ai_extraction/presentation/pages/review_edit_screen.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/transactions/presentation/pages/transaction_form_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/transactions/domain/models/transaction.dart';
import '../../features/transactions/domain/repositories/transaction_repository.dart';
import '../../features/transactions/presentation/bloc/transaction_list_bloc.dart';
import '../../features/transactions/presentation/bloc/transaction_form_bloc.dart';
import '../../features/categories/domain/repositories/category_repository.dart';
import '../../features/categories/presentation/bloc/category_management_bloc.dart';
import '../../features/reports/domain/repositories/report_repository.dart';
import '../../features/reports/presentation/bloc/reports_bloc.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/businesses/domain/repositories/business_repository.dart';
import '../di/injection.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/auth',
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/capture',
      builder: (context, state) => const CaptureScreen(),
    ),
    GoRoute(
      path: '/review-edit',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ReviewEditScreen(
          storagePath: extra['storagePath'] as String? ?? '',
          businessId: extra['businessId'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/transactions',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final businessId = extra['businessId'] as String? ?? '';
        return BlocProvider(
          create: (_) => TransactionListBloc(getIt<TransactionRepository>()),
          child: TransactionsPage(businessId: businessId),
        );
      },
    ),
    GoRoute(
      path: '/transaction-form',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final businessId = extra['businessId'] as String? ?? '';
        final tx = extra['transaction'] as Transaction?;
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => TransactionFormBloc(getIt<TransactionRepository>())),
            BlocProvider(create: (_) => CategoryManagementBloc(getIt<CategoryRepository>())),
          ],
          child: TransactionFormPage(businessId: businessId, initialTransaction: tx),
        );
      },
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final businessId = extra['businessId'] as String? ?? '';
        return BlocProvider(
          create: (_) => CategoryManagementBloc(getIt<CategoryRepository>()),
          child: CategoriesPage(businessId: businessId),
        );
      },
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final businessId = extra['businessId'] as String? ?? '';
        return BlocProvider(
          create: (_) => ReportsBloc(reportRepository: getIt<ReportRepository>())
            ..add(LoadReport(businessId: businessId)),
          child: ReportsPage(businessId: businessId),
        );
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final businessId = extra['businessId'] as String? ?? '';
        return BlocProvider(
          create: (_) => SettingsBloc(
            businessRepository: getIt<BusinessRepository>(),
            supabase: getIt<SupabaseClient>(),
          )..add(LoadSettings(getIt<SupabaseClient>().auth.currentUser?.id ?? '')),
          child: SettingsPage(businessId: businessId),
        );
      },
    ),
  ],
);
