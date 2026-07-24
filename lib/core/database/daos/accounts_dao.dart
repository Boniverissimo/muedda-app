import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/accounts.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Stream<List<Account>> watchAllAccounts() {
    return (select(
      accounts,
    )..orderBy([(table) => OrderingTerm.asc(table.name)])).watch();
  }

  Future<List<Account>> getAllAccounts() {
    return (select(
      accounts,
    )..orderBy([(table) => OrderingTerm.asc(table.name)])).get();
  }

  Future<Account?> getAccountById(int id) {
    return (select(
      accounts,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<int> createAccount(AccountsCompanion account) {
    return into(accounts).insert(account);
  }

  Future<bool> updateAccount(Account account) {
    return update(accounts).replace(account);
  }

  Future<int> updateAccountById({
    required int id,
    String? name,
    int? initialBalanceCents,
    bool? isActive,
  }) {
    return (update(accounts)..where((table) => table.id.equals(id))).write(
      AccountsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        initialBalanceCents: initialBalanceCents != null
            ? Value(initialBalanceCents)
            : const Value.absent(),
        isActive: isActive != null ? Value(isActive) : const Value.absent(),
      ),
    );
  }

  Future<int> deactivateAccount(int id) {
    return (update(accounts)..where((table) => table.id.equals(id))).write(
      const AccountsCompanion(isActive: Value(false)),
    );
  }

  Future<int> deleteAccount(int id) {
    return (delete(accounts)..where((table) => table.id.equals(id))).go();
  }
}
