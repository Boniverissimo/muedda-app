import '../../../../core/database/app_database.dart';

class AccountBalance {
  const AccountBalance({required this.account, required this.balanceCents});

  final Account account;
  final int balanceCents;
}
