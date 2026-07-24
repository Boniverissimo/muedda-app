// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_cards_dao.dart';

// ignore_for_file: type=lint
mixin _$CreditCardsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountsTable get accounts => attachedDatabase.accounts;
  $CreditCardsTable get creditCards => attachedDatabase.creditCards;
  CreditCardsDaoManager get managers => CreditCardsDaoManager(this);
}

class CreditCardsDaoManager {
  final _$CreditCardsDaoMixin _db;
  CreditCardsDaoManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$CreditCardsTableTableManager get creditCards =>
      $$CreditCardsTableTableManager(_db.attachedDatabase, _db.creditCards);
}
