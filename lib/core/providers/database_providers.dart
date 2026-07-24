import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../repositories/accounts_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();

  ref.onDispose(database.close);

  return database;
});

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return AccountsRepository(database.accountsDao);
});

final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  final repository = ref.watch(accountsRepositoryProvider);

  return repository.watchAllAccounts();
});
