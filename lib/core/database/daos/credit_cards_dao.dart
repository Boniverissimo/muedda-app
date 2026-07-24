import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/credit_cards.dart';

part 'credit_cards_dao.g.dart';

@DriftAccessor(tables: [CreditCards])
class CreditCardsDao extends DatabaseAccessor<AppDatabase>
    with _$CreditCardsDaoMixin {
  CreditCardsDao(super.db);

  Stream<List<CreditCard>> watchAllCreditCards() {
    return (select(
      creditCards,
    )..orderBy([(table) => OrderingTerm.asc(table.name)])).watch();
  }

  Stream<List<CreditCard>> watchActiveCreditCards() {
    return (select(creditCards)
          ..where((table) => table.isActive.equals(true))
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .watch();
  }

  Future<List<CreditCard>> getAllCreditCards() {
    return (select(
      creditCards,
    )..orderBy([(table) => OrderingTerm.asc(table.name)])).get();
  }

  Future<CreditCard?> getCreditCardById(int id) {
    return (select(
      creditCards,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<int> createCreditCard(CreditCardsCompanion card) {
    return into(creditCards).insert(card);
  }

  Future<bool> updateCreditCard(CreditCard card) {
    return update(creditCards).replace(card);
  }

  Future<int> updateCreditCardById({
    required int id,
    String? name,
    int? accountId,
    int? limitCents,
    int? closingDay,
    int? dueDay,
    String? colorHex,
    bool? isActive,
  }) {
    return (update(creditCards)..where((table) => table.id.equals(id))).write(
      CreditCardsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        accountId: accountId != null ? Value(accountId) : const Value.absent(),
        limitCents: limitCents != null
            ? Value(limitCents)
            : const Value.absent(),
        closingDay: closingDay != null
            ? Value(closingDay)
            : const Value.absent(),
        dueDay: dueDay != null ? Value(dueDay) : const Value.absent(),
        colorHex: colorHex != null ? Value(colorHex) : const Value.absent(),
        isActive: isActive != null ? Value(isActive) : const Value.absent(),
      ),
    );
  }

  Future<int> deactivateCreditCard(int id) {
    return (update(creditCards)..where((table) => table.id.equals(id))).write(
      const CreditCardsCompanion(isActive: Value(false)),
    );
  }

  Future<int> deleteCreditCard(int id) {
    return (delete(creditCards)..where((table) => table.id.equals(id))).go();
  }
}
