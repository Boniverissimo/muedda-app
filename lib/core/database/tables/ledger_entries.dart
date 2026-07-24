import 'package:drift/drift.dart';

import 'accounts.dart';
import 'categories.dart';
import 'credit_cards.dart';

class LedgerEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get description => text().withLength(min: 1, max: 150)();

  // Valor armazenado em centavos.
  IntColumn get amountCents => integer()();

  // income, expense ou transfer
  TextColumn get type => text().withLength(min: 6, max: 8)();

  @ReferenceName('sourceAccountEntries')
  IntColumn get accountId => integer().references(Accounts, #id)();

  @ReferenceName('destinationAccountEntries')
  IntColumn get destinationAccountId =>
      integer().nullable().references(Accounts, #id)();

  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  IntColumn get creditCardId =>
      integer().nullable().references(CreditCards, #id)();

  DateTimeColumn get occurredAt => dateTime()();

  DateTimeColumn get dueDate => dateTime().nullable()();

  BoolColumn get isPaid => boolean().withDefault(const Constant(true))();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
