import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/daos/recurring_transactions_dao.dart';

class RecurringTransactionsRepository {
  RecurringTransactionsRepository(this._dao);

  final RecurringTransactionsDao _dao;

  Stream<List<RecurringTransaction>> watchAllRecurringTransactions() {
    return _dao.watchAllRecurringTransactions();
  }

  Stream<List<RecurringTransaction>> watchActiveRecurringTransactions() {
    return _dao.watchActiveRecurringTransactions();
  }

  Future<List<RecurringTransaction>> getAllRecurringTransactions() {
    return _dao.getAllRecurringTransactions();
  }

  Future<RecurringTransaction?> getRecurringTransactionById(int id) {
    return _dao.getRecurringTransactionById(id);
  }

  Future<List<RecurringTransaction>> getDueRecurringTransactions(
    DateTime until,
  ) {
    return _dao.getDueRecurringTransactions(until);
  }

  Future<int> createRecurringTransaction({
    required String description,
    required int amountCents,
    required String type,
    required int accountId,
    required String frequency,
    required DateTime startDate,
    required DateTime nextOccurrence,
    int? categoryId,
    int intervalCount = 1,
    DateTime? endDate,
    bool isActive = true,
    bool autoGenerate = true,
    String? notes,
  }) {
    return _dao.createRecurringTransaction(
      RecurringTransactionsCompanion.insert(
        description: description,
        amountCents: amountCents,
        type: type,
        accountId: accountId,
        categoryId: Value(categoryId),
        frequency: frequency,
        intervalCount: Value(intervalCount),
        startDate: startDate,
        endDate: Value(endDate),
        nextOccurrence: nextOccurrence,
        isActive: Value(isActive),
        autoGenerate: Value(autoGenerate),
        notes: Value(notes),
      ),
    );
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
    return _dao.updateRecurringTransaction(
      id: id,
      description: description,
      amountCents: amountCents,
      type: type,
      accountId: accountId,
      categoryId: categoryId,
      frequency: frequency,
      intervalCount: intervalCount,
      startDate: startDate,
      endDate: endDate,
      nextOccurrence: nextOccurrence,
      lastGeneratedAt: lastGeneratedAt,
      isActive: isActive,
      autoGenerate: autoGenerate,
      notes: notes,
    );
  }

  Future<int> pauseRecurringTransaction(int id) {
    return _dao.setActive(id: id, isActive: false);
  }

  Future<int> reactivateRecurringTransaction(int id) {
    return _dao.setActive(id: id, isActive: true);
  }

  Future<int> updateAfterGeneration({
    required int id,
    required DateTime generatedAt,
    required DateTime nextOccurrence,
    required bool isActive,
  }) {
    return _dao.updateAfterGeneration(
      id: id,
      generatedAt: generatedAt,
      nextOccurrence: nextOccurrence,
      isActive: isActive,
    );
  }

  Future<int> deleteRecurringTransaction(int id) {
    return _dao.deleteRecurringTransaction(id);
  }
}
