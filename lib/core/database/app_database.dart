import 'package:drift/drift.dart';

import 'connection/database_connection.dart';
import 'tables/accounts.dart';
import 'tables/categories.dart';
import 'tables/credit_cards.dart';
import 'tables/ledger_entries.dart';
import 'tables/recurring_transactions.dart';
import 'daos/accounts_dao.dart';
import 'daos/categories_dao.dart'; // ← coloque aqui
import 'daos/credit_cards_dao.dart';
import 'daos/ledger_entries_dao.dart';
import 'daos/recurring_transactions_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    CreditCards,
    LedgerEntries,
    RecurringTransactions,
  ],
  daos: [
    AccountsDao,
    CategoriesDao,
    CreditCardsDao,
    LedgerEntriesDao,
    RecurringTransactionsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(recurringTransactions);
      }
    },
  );
}
