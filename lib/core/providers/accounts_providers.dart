import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../repositories/accounts_repository.dart';
import 'database_providers.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return AccountsRepository(database.accountsDao);
});

final accountsStreamProvider = StreamProvider.autoDispose<List<Account>>((ref) {
  final repository = ref.watch(accountsRepositoryProvider);

  return repository.watchAllAccounts();
});

final activeAccountsStreamProvider = StreamProvider.autoDispose<List<Account>>((
  ref,
) {
  final repository = ref.watch(accountsRepositoryProvider);

  return repository.watchAllAccounts().map(
    (accounts) =>
        accounts.where((account) => account.isActive).toList(growable: false),
  );
});
