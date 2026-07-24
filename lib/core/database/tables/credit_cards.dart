import 'package:drift/drift.dart';

import 'accounts.dart';

class CreditCards extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 80)();

  IntColumn get accountId => integer().references(Accounts, #id)();

  IntColumn get limitCents => integer().withDefault(const Constant(0))();

  IntColumn get closingDay => integer()();

  IntColumn get dueDay => integer()();

  TextColumn get colorHex => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
