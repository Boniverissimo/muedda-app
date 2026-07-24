import '../repositories/ledger_entries_repository.dart';
import '../repositories/recurring_transactions_repository.dart';

class RecurringGenerationResult {
  const RecurringGenerationResult({
    required this.createdEntries,
    required this.processedRules,
  });

  final int createdEntries;
  final int processedRules;
}

class RecurringGenerationService {
  RecurringGenerationService({
    required RecurringTransactionsRepository recurringRepository,
    required LedgerEntriesRepository ledgerRepository,
  }) : _recurringRepository = recurringRepository,
       _ledgerRepository = ledgerRepository;

  final RecurringTransactionsRepository _recurringRepository;
  final LedgerEntriesRepository _ledgerRepository;

  Future<RecurringGenerationResult> generateDueEntries({
    DateTime? until,
  }) async {
    final limit = _dateOnly(until ?? DateTime.now());
    final rules = await _recurringRepository.getDueRecurringTransactions(limit);
    final existingEntries = await _ledgerRepository.getAllEntries();
    final existingMarkers = existingEntries
        .map((entry) => entry.notes)
        .whereType<String>()
        .toSet();

    var createdEntries = 0;

    for (final rule in rules) {
      var occurrence = _dateOnly(rule.nextOccurrence);
      var lastGeneratedAt = rule.lastGeneratedAt;
      var isActive = rule.isActive;

      while (!occurrence.isAfter(limit) && isActive) {
        if (rule.endDate != null &&
            occurrence.isAfter(_dateOnly(rule.endDate!))) {
          isActive = false;
          break;
        }

        final marker = _marker(rule.id, occurrence);
        if (!existingMarkers.contains(marker)) {
          await _ledgerRepository.createEntry(
            description: rule.description,
            amountCents: rule.amountCents,
            type: rule.type,
            accountId: rule.accountId,
            categoryId: rule.categoryId,
            occurredAt: occurrence,
            dueDate: occurrence,
            isPaid: false,
            notes: marker,
          );
          existingMarkers.add(marker);
          createdEntries++;
        }

        lastGeneratedAt = occurrence;
        occurrence = nextOccurrence(
          occurrence,
          frequency: rule.frequency,
          intervalCount: rule.intervalCount,
        );

        if (rule.endDate != null &&
            occurrence.isAfter(_dateOnly(rule.endDate!))) {
          isActive = false;
        }
      }

      await _recurringRepository.updateAfterGeneration(
        id: rule.id,
        generatedAt: lastGeneratedAt ?? DateTime.now(),
        nextOccurrence: occurrence,
        isActive: isActive,
      );
    }

    return RecurringGenerationResult(
      createdEntries: createdEntries,
      processedRules: rules.length,
    );
  }

  static DateTime nextOccurrence(
    DateTime current, {
    required String frequency,
    int intervalCount = 1,
  }) {
    final interval = intervalCount < 1 ? 1 : intervalCount;

    switch (frequency) {
      case 'daily':
        return current.add(Duration(days: interval));
      case 'weekly':
        return current.add(Duration(days: 7 * interval));
      case 'biweekly':
        return current.add(Duration(days: 14 * interval));
      case 'bimonthly':
        return _addMonths(current, 2 * interval);
      case 'quarterly':
        return _addMonths(current, 3 * interval);
      case 'semiannual':
        return _addMonths(current, 6 * interval);
      case 'yearly':
        return _addMonths(current, 12 * interval);
      case 'monthly':
      default:
        return _addMonths(current, interval);
    }
  }

  static DateTime _addMonths(DateTime date, int months) {
    final target = DateTime(date.year, date.month + months);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(target.year, target.month, day);
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _marker(int ruleId, DateTime occurrence) {
    final month = occurrence.month.toString().padLeft(2, '0');
    final day = occurrence.day.toString().padLeft(2, '0');
    return 'recurring:$ruleId:${occurrence.year}-$month-$day';
  }
}
