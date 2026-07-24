import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../repositories/recurring_transactions_repository.dart';
import 'database_providers.dart';

final recurringTransactionsRepositoryProvider =
    Provider<RecurringTransactionsRepository>((ref) {
      final database = ref.watch(appDatabaseProvider);
      return RecurringTransactionsRepository(database.recurringTransactionsDao);
    });

final recurringTransactionsStreamProvider =
    StreamProvider<List<RecurringTransaction>>((ref) {
      final repository = ref.watch(recurringTransactionsRepositoryProvider);
      return repository.watchAllRecurringTransactions();
    });

final activeRecurringTransactionsStreamProvider =
    StreamProvider<List<RecurringTransaction>>((ref) {
      final repository = ref.watch(recurringTransactionsRepositoryProvider);
      return repository.watchActiveRecurringTransactions();
    });

final recurringTransactionByIdProvider =
    FutureProvider.family<RecurringTransaction?, int>((ref, id) {
      final repository = ref.watch(recurringTransactionsRepositoryProvider);
      return repository.getRecurringTransactionById(id);
    });
