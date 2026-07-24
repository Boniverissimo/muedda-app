import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/daos/ledger_entries_dao.dart';

class LedgerEntriesRepository {
  LedgerEntriesRepository(this._ledgerEntriesDao);

  final LedgerEntriesDao _ledgerEntriesDao;

  Stream<List<LedgerEntry>> watchAllEntries() {
    return _ledgerEntriesDao.watchAllEntries();
  }

  Stream<List<LedgerEntry>> watchEntriesByType(String type) {
    return _ledgerEntriesDao.watchEntriesByType(type);
  }

  Stream<List<LedgerEntry>> watchEntriesByAccount(int accountId) {
    return _ledgerEntriesDao.watchEntriesByAccount(accountId);
  }

  Stream<List<LedgerEntry>> watchEntriesByPeriod({
    required DateTime start,
    required DateTime end,
  }) {
    return _ledgerEntriesDao.watchEntriesByPeriod(start: start, end: end);
  }

  Stream<List<LedgerEntry>> watchEntriesByCreditCard(int creditCardId) {
    return _ledgerEntriesDao.watchEntriesByCreditCard(creditCardId);
  }

  Future<List<LedgerEntry>> getEntriesByCreditCard(int creditCardId) {
    return _ledgerEntriesDao.getEntriesByCreditCard(creditCardId);
  }

  Future<List<LedgerEntry>> getAllEntries() {
    return _ledgerEntriesDao.getAllEntries();
  }

  Future<LedgerEntry?> getEntryById(int id) {
    return _ledgerEntriesDao.getEntryById(id);
  }

  Future<int> createEntry({
    required String description,
    required int amountCents,
    required String type,
    required int accountId,
    required DateTime occurredAt,
    int? destinationAccountId,
    int? categoryId,
    int? creditCardId,
    DateTime? dueDate,
    bool isPaid = true,
    String? notes,
  }) {
    return _ledgerEntriesDao.createEntry(
      LedgerEntriesCompanion.insert(
        description: description,
        amountCents: amountCents,
        type: type,
        accountId: accountId,
        destinationAccountId: Value(destinationAccountId),
        categoryId: Value(categoryId),
        creditCardId: Value(creditCardId),
        occurredAt: occurredAt,
        dueDate: Value(dueDate),
        isPaid: Value(isPaid),
        notes: Value(notes),
      ),
    );
  }

  Future<int> updateEntry({
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
    return _ledgerEntriesDao.updateEntryById(
      id: id,
      description: description,
      amountCents: amountCents,
      type: type,
      accountId: accountId,
      destinationAccountId: destinationAccountId,
      categoryId: categoryId,
      creditCardId: creditCardId,
      occurredAt: occurredAt,
      dueDate: dueDate,
      isPaid: isPaid,
      notes: notes,
    );
  }

  Future<int> markAsPaid(int id) {
    return _ledgerEntriesDao.markAsPaid(id);
  }

  Future<int> markAsPending(int id) {
    return _ledgerEntriesDao.markAsPending(id);
  }

  Future<int> deleteEntry(int id) {
    return _ledgerEntriesDao.deleteEntry(id);
  }
}
