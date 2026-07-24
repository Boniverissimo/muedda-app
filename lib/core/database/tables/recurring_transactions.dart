import 'package:drift/drift.dart';

import 'accounts.dart';
import 'categories.dart';

/// Regras usadas para gerar receitas e despesas recorrentes.
///
/// Os lançamentos efetivos continuam sendo armazenados em [LedgerEntries].
class RecurringTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get description => text().withLength(min: 1, max: 150)();

  // Valor armazenado em centavos.
  IntColumn get amountCents => integer()();

  // income ou expense.
  TextColumn get type => text().withLength(min: 6, max: 7)();

  IntColumn get accountId => integer().references(Accounts, #id)();

  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  // daily, weekly, biweekly, monthly, bimonthly, quarterly, semiannual ou yearly.
  TextColumn get frequency => text().withLength(min: 5, max: 16)();

  // Permite frequências personalizadas no futuro, como a cada 2 meses.
  IntColumn get intervalCount => integer().withDefault(const Constant(1))();

  DateTimeColumn get startDate => dateTime()();

  DateTimeColumn get endDate => dateTime().nullable()();

  DateTimeColumn get nextOccurrence => dateTime()();

  DateTimeColumn get lastGeneratedAt => dateTime().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  BoolColumn get autoGenerate => boolean().withDefault(const Constant(true))();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
