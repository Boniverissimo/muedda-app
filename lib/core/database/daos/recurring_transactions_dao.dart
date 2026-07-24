import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/recurring_transactions.dart';

part 'recurring_transactions_dao.g.dart';

@DriftAccessor(tables: [RecurringTransactions])
class RecurringTransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringTransactionsDaoMixin {
  RecurringTransactionsDao(super.db);

  Stream<List<RecurringTransaction>> watchAllRecurringTransactions() {
    return (select(recurringTransactions)..orderBy([
          (table) => OrderingTerm.desc(table.isActive),
          (table) => OrderingTerm.asc(table.nextOccurrence),
          (table) => OrderingTerm.asc(table.description),
        ]))
        .watch();
  }

  Stream<List<RecurringTransaction>> watchActiveRecurringTransactions() {
    return (select(recurringTransactions)
          ..where((table) => table.isActive.equals(true))
          ..orderBy([
            (table) => OrderingTerm.asc(table.nextOccurrence),
            (table) => OrderingTerm.asc(table.description),
          ]))
        .watch();
  }

  Future<List<RecurringTransaction>> getAllRecurringTransactions() {
    return (select(recurringTransactions)..orderBy([
          (table) => OrderingTerm.desc(table.isActive),
          (table) => OrderingTerm.asc(table.nextOccurrence),
        ]))
        .get();
  }

  Future<RecurringTransaction?> getRecurringTransactionById(int id) {
    return (select(
      recurringTransactions,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<List<RecurringTransaction>> getDueRecurringTransactions(
    DateTime until,
  ) {
    return (select(recurringTransactions)
          ..where(
            (table) =>
                table.isActive.equals(true) &
                table.autoGenerate.equals(true) &
                table.nextOccurrence.isSmallerOrEqualValue(until) &
                (table.endDate.isNull() |
                    table.nextOccurrence.isSmallerOrEqual(table.endDate)),
          )
          ..orderBy([(table) => OrderingTerm.asc(table.nextOccurrence)]))
        .get();
  }

  Future<int> createRecurringTransaction(
    RecurringTransactionsCompanion recurringTransaction,
  ) {
    return into(recurringTransactions).insert(recurringTransaction);
  }

  Future<bool> replaceRecurringTransaction(
    RecurringTransaction recurringTransaction,
  ) {
    return update(recurringTransactions).replace(recurringTransaction);
  }

  Future<int> updateRecurringTransaction({
    required int id,
    String? description,
    int? amountCents,
    String? type,
    int? accountId,
    Value<int?> categoryId = const Value.absent(),
    String? frequency,
    int? intervalCount,
    DateTime? startDate,
    Value<DateTime?> endDate = const Value.absent(),
    DateTime? nextOccurrence,
    Value<DateTime?> lastGeneratedAt = const Value.absent(),
    bool? isActive,
    bool? autoGenerate,
    Value<String?> notes = const Value.absent(),
  }) {
    return (update(
      recurringTransactions,
    )..where((table) => table.id.equals(id))).write(
      RecurringTransactionsCompanion(
        description: description != null
            ? Value(description)
            : const Value.absent(),
        amountCents: amountCents != null
            ? Value(amountCents)
            : const Value.absent(),
        type: type != null ? Value(type) : const Value.absent(),
        accountId: accountId != null ? Value(accountId) : const Value.absent(),
        categoryId: categoryId,
        frequency: frequency != null ? Value(frequency) : const Value.absent(),
        intervalCount: intervalCount != null
            ? Value(intervalCount)
            : const Value.absent(),
        startDate: startDate != null ? Value(startDate) : const Value.absent(),
        endDate: endDate,
        nextOccurrence: nextOccurrence != null
            ? Value(nextOccurrence)
            : const Value.absent(),
        lastGeneratedAt: lastGeneratedAt,
        isActive: isActive != null ? Value(isActive) : const Value.absent(),
        autoGenerate: autoGenerate != null
            ? Value(autoGenerate)
            : const Value.absent(),
        notes: notes,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> setActive({required int id, required bool isActive}) {
    return updateRecurringTransaction(id: id, isActive: isActive);
  }

  Future<int> updateAfterGeneration({
    required int id,
    required DateTime generatedAt,
    required DateTime nextOccurrence,
    required bool isActive,
  }) {
    return updateRecurringTransaction(
      id: id,
      lastGeneratedAt: Value(generatedAt),
      nextOccurrence: nextOccurrence,
      isActive: isActive,
    );
  }

  Future<int> deleteRecurringTransaction(int id) {
    return (delete(
      recurringTransactions,
    )..where((table) => table.id.equals(id))).go();
  }
}
