import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/accounts.dart';
import '../tables/categories.dart';
import '../tables/credit_cards.dart';
import '../tables/ledger_entries.dart';

part 'ledger_entries_dao.g.dart';

@DriftAccessor(tables: [LedgerEntries, Accounts, Categories, CreditCards])
class LedgerEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$LedgerEntriesDaoMixin {
  LedgerEntriesDao(super.db);

  Stream<List<LedgerEntry>> watchAllEntries() {
    return (select(
      ledgerEntries,
    )..orderBy([(table) => OrderingTerm.desc(table.occurredAt)])).watch();
  }

  Stream<List<LedgerEntry>> watchEntriesByType(String type) {
    return (select(ledgerEntries)
          ..where((table) => table.type.equals(type))
          ..orderBy([(table) => OrderingTerm.desc(table.occurredAt)]))
        .watch();
  }

  Stream<List<LedgerEntry>> watchEntriesByAccount(int accountId) {
    return (select(ledgerEntries)
          ..where((table) => table.accountId.equals(accountId))
          ..orderBy([(table) => OrderingTerm.desc(table.occurredAt)]))
        .watch();
  }

  Stream<List<LedgerEntry>> watchEntriesByPeriod({
    required DateTime start,
    required DateTime end,
  }) {
    return (select(ledgerEntries)
          ..where(
            (table) =>
                table.occurredAt.isBiggerOrEqualValue(start) &
                table.occurredAt.isSmallerOrEqualValue(end),
          )
          ..orderBy([(table) => OrderingTerm.desc(table.occurredAt)]))
        .watch();
  }

  Stream<List<LedgerEntry>> watchEntriesByCreditCard(int creditCardId) {
    return (select(ledgerEntries)
          ..where((table) => table.creditCardId.equals(creditCardId))
          ..orderBy([
            (table) => OrderingTerm.desc(table.dueDate),
            (table) => OrderingTerm.desc(table.occurredAt),
          ]))
        .watch();
  }

  Future<List<LedgerEntry>> getEntriesByCreditCard(int creditCardId) {
    return (select(ledgerEntries)
          ..where((table) => table.creditCardId.equals(creditCardId))
          ..orderBy([
            (table) => OrderingTerm.desc(table.dueDate),
            (table) => OrderingTerm.desc(table.occurredAt),
          ]))
        .get();
  }

  Future<List<LedgerEntry>> getAllEntries() {
    return (select(
      ledgerEntries,
    )..orderBy([(table) => OrderingTerm.desc(table.occurredAt)])).get();
  }

  Future<LedgerEntry?> getEntryById(int id) {
    return (select(
      ledgerEntries,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<int> createEntry(LedgerEntriesCompanion entry) {
    return into(ledgerEntries).insert(entry);
  }

  Future<bool> updateEntry(LedgerEntry entry) {
    return update(ledgerEntries).replace(entry);
  }

  Future<int> updateEntryById({
    required int id,
    String? description,
    int? amountCents,
    String? type,
    int? accountId,
    int? destinationAccountId,
    int? categoryId,
    int? creditCardId,
    DateTime? occurredAt,
    DateTime? dueDate,
    bool? isPaid,
    String? notes,
  }) {
    return (update(ledgerEntries)..where((table) => table.id.equals(id))).write(
      LedgerEntriesCompanion(
        description: description != null
            ? Value(description)
            : const Value.absent(),
        amountCents: amountCents != null
            ? Value(amountCents)
            : const Value.absent(),
        type: type != null ? Value(type) : const Value.absent(),
        accountId: accountId != null ? Value(accountId) : const Value.absent(),
        destinationAccountId: destinationAccountId != null
            ? Value(destinationAccountId)
            : const Value.absent(),
        categoryId: categoryId != null
            ? Value(categoryId)
            : const Value.absent(),
        creditCardId: creditCardId != null
            ? Value(creditCardId)
            : const Value.absent(),
        occurredAt: occurredAt != null
            ? Value(occurredAt)
            : const Value.absent(),
        dueDate: dueDate != null ? Value(dueDate) : const Value.absent(),
        isPaid: isPaid != null ? Value(isPaid) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> markAsPaid(int id) {
    return (update(ledgerEntries)..where((table) => table.id.equals(id))).write(
      LedgerEntriesCompanion(
        isPaid: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> markAsPending(int id) {
    return (update(ledgerEntries)..where((table) => table.id.equals(id))).write(
      LedgerEntriesCompanion(
        isPaid: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteEntry(int id) {
    return (delete(ledgerEntries)..where((table) => table.id.equals(id))).go();
  }
}
