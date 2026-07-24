import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 80)();

  // income ou expense
  TextColumn get type => text().withLength(min: 6, max: 7)();

  TextColumn get iconName => text().nullable()();

  TextColumn get colorHex => text().nullable()();

  IntColumn get parentCategoryId => integer().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
