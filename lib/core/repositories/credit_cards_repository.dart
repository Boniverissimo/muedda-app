import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/daos/credit_cards_dao.dart';

class CreditCardsRepository {
  CreditCardsRepository(this._creditCardsDao);

  final CreditCardsDao _creditCardsDao;

  Stream<List<CreditCard>> watchAllCreditCards() {
    return _creditCardsDao.watchAllCreditCards();
  }

  Stream<List<CreditCard>> watchActiveCreditCards() {
    return _creditCardsDao.watchActiveCreditCards();
  }

  Future<List<CreditCard>> getAllCreditCards() {
    return _creditCardsDao.getAllCreditCards();
  }

  Future<CreditCard?> getCreditCardById(int id) {
    return _creditCardsDao.getCreditCardById(id);
  }

  Future<int> createCreditCard({
    required String name,
    required int accountId,
    required int closingDay,
    required int dueDay,
    int limitCents = 0,
    String? colorHex,
  }) {
    return _creditCardsDao.createCreditCard(
      CreditCardsCompanion.insert(
        name: name,
        accountId: accountId,
        closingDay: closingDay,
        dueDay: dueDay,
        limitCents: Value(limitCents),
        colorHex: Value(colorHex),
      ),
    );
  }

  Future<int> updateCreditCard({
    required int id,
    String? name,
    int? accountId,
    int? limitCents,
    int? closingDay,
    int? dueDay,
    String? colorHex,
    bool? isActive,
  }) {
    return _creditCardsDao.updateCreditCardById(
      id: id,
      name: name,
      accountId: accountId,
      limitCents: limitCents,
      closingDay: closingDay,
      dueDay: dueDay,
      colorHex: colorHex,
      isActive: isActive,
    );
  }

  Future<int> deactivateCreditCard(int id) {
    return _creditCardsDao.deactivateCreditCard(id);
  }

  Future<int> deleteCreditCard(int id) {
    return _creditCardsDao.deleteCreditCard(id);
  }
}
