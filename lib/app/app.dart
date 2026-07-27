import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/ledger_entries_providers.dart';
import '../core/providers/recurring_transactions_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class FinanceApp extends ConsumerStatefulWidget {
  const FinanceApp({super.key});

  @override
  ConsumerState<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends ConsumerState<FinanceApp> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_generateRecurringEntries);
  }

  Future<void> _generateRecurringEntries() async {
    try {
      final service = ref.read(recurringGenerationServiceProvider);
      final result = await service.generateDueEntries();

      if (result.createdEntries > 0) {
        ref.invalidate(ledgerEntriesStreamProvider);
        ref.invalidate(recurringTransactionsStreamProvider);
        ref.invalidate(activeRecurringTransactionsStreamProvider);
      }
    } catch (_) {
      // A geração será tentada novamente na próxima abertura do aplicativo.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
