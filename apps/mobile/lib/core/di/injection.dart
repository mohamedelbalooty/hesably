import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hesably_mobile/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:hesably_mobile/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:hesably_mobile/features/categories/domain/repositories/category_repository.dart';
import 'package:hesably_mobile/features/categories/data/repositories/category_repository_impl.dart';
import 'package:hesably_mobile/features/businesses/domain/repositories/business_repository.dart';
import 'package:hesably_mobile/features/businesses/data/repositories/business_repository_impl.dart';
import 'package:hesably_mobile/features/reports/domain/repositories/report_repository.dart';
import 'package:hesably_mobile/features/reports/data/repositories/report_repository_impl.dart';

final getIt = GetIt.instance;

void setupInjection() {
  // Supabase Client
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Repositories
  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<BusinessRepository>(
    () => BusinessRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(getIt<SupabaseClient>()),
  );
}
