import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../repositories/credit_cards_repository.dart';
import 'database_providers.dart';

final creditCardsRepositoryProvider = Provider<CreditCardsRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return CreditCardsRepository(database.creditCardsDao);
});

final creditCardsStreamProvider = StreamProvider.autoDispose<List<CreditCard>>((
  ref,
) {
  final repository = ref.watch(creditCardsRepositoryProvider);

  return repository.watchAllCreditCards();
});

final activeCreditCardsStreamProvider =
    StreamProvider.autoDispose<List<CreditCard>>((ref) {
      final repository = ref.watch(creditCardsRepositoryProvider);

      return repository.watchActiveCreditCards();
    });
