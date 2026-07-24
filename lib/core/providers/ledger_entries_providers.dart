import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../repositories/ledger_entries_repository.dart';
import 'database_providers.dart';

final ledgerEntriesRepositoryProvider = Provider<LedgerEntriesRepository>((
  ref,
) {
  final database = ref.watch(appDatabaseProvider);

  return LedgerEntriesRepository(database.ledgerEntriesDao);
});

final ledgerEntriesStreamProvider = StreamProvider<List<LedgerEntry>>((ref) {
  final repository = ref.watch(ledgerEntriesRepositoryProvider);

  return repository.watchAllEntries();
});

final incomeEntriesStreamProvider = StreamProvider<List<LedgerEntry>>((ref) {
  final repository = ref.watch(ledgerEntriesRepositoryProvider);

  return repository.watchEntriesByType('income');
});

final expenseEntriesStreamProvider = StreamProvider<List<LedgerEntry>>((ref) {
  final repository = ref.watch(ledgerEntriesRepositoryProvider);

  return repository.watchEntriesByType('expense');
});

final entriesByAccountStreamProvider =
    StreamProvider.family<List<LedgerEntry>, int>((ref, accountId) {
      final repository = ref.watch(ledgerEntriesRepositoryProvider);

      return repository.watchEntriesByAccount(accountId);
    });

class LedgerEntriesPeriod {
  const LedgerEntriesPeriod({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) {
    return other is LedgerEntriesPeriod &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode {
    return Object.hash(start, end);
  }
}

final entriesByPeriodStreamProvider =
    StreamProvider.family<List<LedgerEntry>, LedgerEntriesPeriod>((
      ref,
      period,
    ) {
      final repository = ref.watch(ledgerEntriesRepositoryProvider);

      return repository.watchEntriesByPeriod(
        start: period.start,
        end: period.end,
      );
    });

enum DashboardPeriodType { today, week, month, year }

final dashboardPeriodTypeProvider = StateProvider<DashboardPeriodType>((ref) {
  return DashboardPeriodType.month;
});

final dashboardReferenceDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final dashboardPeriodProvider = Provider<LedgerEntriesPeriod>((ref) {
  final periodType = ref.watch(dashboardPeriodTypeProvider);
  final referenceDate = ref.watch(dashboardReferenceDateProvider);

  late DateTime start;
  late DateTime end;

  switch (periodType) {
    case DashboardPeriodType.today:
      start = DateTime(
        referenceDate.year,
        referenceDate.month,
        referenceDate.day,
      );

      end = start
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1));

    case DashboardPeriodType.week:
      final beginningOfDay = DateTime(
        referenceDate.year,
        referenceDate.month,
        referenceDate.day,
      );

      start = beginningOfDay.subtract(
        Duration(days: beginningOfDay.weekday - DateTime.monday),
      );

      end = start
          .add(const Duration(days: 7))
          .subtract(const Duration(microseconds: 1));

    case DashboardPeriodType.month:
      start = DateTime(referenceDate.year, referenceDate.month);

      end = DateTime(
        referenceDate.year,
        referenceDate.month + 1,
      ).subtract(const Duration(microseconds: 1));

    case DashboardPeriodType.year:
      start = DateTime(referenceDate.year);

      end = DateTime(
        referenceDate.year + 1,
      ).subtract(const Duration(microseconds: 1));
  }

  return LedgerEntriesPeriod(start: start, end: end);
});
final entriesByCreditCardStreamProvider = StreamProvider.autoDispose
    .family<List<LedgerEntry>, int>((ref, cardId) {
      final repository = ref.watch(ledgerEntriesRepositoryProvider);
      return repository.watchEntriesByCreditCard(cardId);
    });
