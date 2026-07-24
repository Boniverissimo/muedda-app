import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/daos/accounts_dao.dart';

class AccountsRepository {
  AccountsRepository(this._accountsDao);

  final AccountsDao _accountsDao;

  Stream<List<Account>> watchAllAccounts() {
    return _accountsDao.watchAllAccounts();
  }

  Future<List<Account>> getAllAccounts() {
    return _accountsDao.getAllAccounts();
  }

  Future<Account?> getAccountById(int id) {
    return _accountsDao.getAccountById(id);
  }

  Future<int> createAccount({
    required String name,
    int initialBalanceCents = 0,
  }) {
    return _accountsDao.createAccount(
      AccountsCompanion.insert(
        name: name,
        initialBalanceCents: Value(initialBalanceCents),
      ),
    );
  }

  Future<int> updateAccount({
    required int id,
    String? name,
    int? initialBalanceCents,
    bool? isActive,
  }) {
    return _accountsDao.updateAccountById(
      id: id,
      name: name,
      initialBalanceCents: initialBalanceCents,
      isActive: isActive,
    );
  }

  Future<int> deactivateAccount(int id) {
    return _accountsDao.deactivateAccount(id);
  }

  Future<int> deleteAccount(int id) {
    return _accountsDao.deleteAccount(id);
  }
}
