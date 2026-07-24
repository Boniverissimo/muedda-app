// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_entries_dao.dart';

// ignore_for_file: type=lint
mixin _$LedgerEntriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountsTable get accounts => attachedDatabase.accounts;
  $CategoriesTable get categories => attachedDatabase.categories;
  $CreditCardsTable get creditCards => attachedDatabase.creditCards;
  $LedgerEntriesTable get ledgerEntries => attachedDatabase.ledgerEntries;
  LedgerEntriesDaoManager get managers => LedgerEntriesDaoManager(this);
}

class LedgerEntriesDaoManager {
  final _$LedgerEntriesDaoMixin _db;
  LedgerEntriesDaoManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$CreditCardsTableTableManager get creditCards =>
      $$CreditCardsTableTableManager(_db.attachedDatabase, _db.creditCards);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db.attachedDatabase, _db.ledgerEntries);
}
