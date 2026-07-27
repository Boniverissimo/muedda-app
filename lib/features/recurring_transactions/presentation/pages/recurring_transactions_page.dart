import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

import '../../../../core/ui/components/muedda_back_button.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/ledger_entries_providers.dart';
import '../../../../core/providers/recurring_transactions_providers.dart';
import '../widgets/recurring_transaction_form_dialog.dart';

class RecurringTransactionsPage extends ConsumerWidget {
  const RecurringTransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringTransactionsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const MueddaBackButton(),
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Recorrências', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Gerar lançamentos pendentes',
            onPressed: () => _generateNow(context, ref),
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: recurringAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Erro ao carregar recorrências: $error'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 112,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return _RecurringCard(
                item: item,
                onTap: () => _showOptions(context, ref, item),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        heroTag: 'recurring_transactions_fab',
        onPressed: () =>
            showRecurringTransactionFormDialog(context: context, ref: ref),
        icon: const Icon(Icons.add),
        label: const Text('Nova recorrência'),
      ),
    );
  }

  Future<void> _generateNow(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(recurringGenerationServiceProvider)
          .generateDueEntries();
      ref.invalidate(ledgerEntriesStreamProvider);
      ref.invalidate(recurringTransactionsStreamProvider);
      ref.invalidate(activeRecurringTransactionsStreamProvider);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.createdEntries == 0
                ? 'Nenhum lançamento pendente para gerar.'
                : '${result.createdEntries} lançamento(s) gerado(s).',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Não foi possível gerar as recorrências: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showOptions(
    BuildContext context,
    WidgetRef ref,
    RecurringTransaction item,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showRecurringTransactionFormDialog(
                    context: context,
                    ref: ref,
                    recurringTransaction: item,
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  item.isActive
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                ),
                title: Text(item.isActive ? 'Pausar' : 'Reativar'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final repository = ref.read(
                    recurringTransactionsRepositoryProvider,
                  );
                  if (item.isActive) {
                    await repository.pauseRecurringTransaction(item.id);
                  } else {
                    await repository.updateRecurringTransaction(
                      id: item.id,
                      isActive: true,
                      nextOccurrence: _nextValidOccurrence(item),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Excluir'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDelete(context, ref, item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RecurringTransaction item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir recorrência?'),
        content: Text(
          'A recorrência “${item.description}” será removida. '
          'Os lançamentos já criados não serão apagados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref
        .read(recurringTransactionsRepositoryProvider)
        .deleteRecurringTransaction(item.id);
  }

  DateTime _nextValidOccurrence(RecurringTransaction item) {
    final today = DateUtils.dateOnly(DateTime.now());
    var next = DateUtils.dateOnly(item.nextOccurrence);
    while (next.isBefore(today)) {
      next = _addFrequency(next, item.frequency);
    }
    return next;
  }

  DateTime _addFrequency(DateTime date, String frequency) {
    switch (frequency) {
      case 'daily':
        return date.add(const Duration(days: 1));
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'biweekly':
        return date.add(const Duration(days: 14));
      case 'bimonthly':
        return _addMonths(date, 2);
      case 'quarterly':
        return _addMonths(date, 3);
      case 'semiannual':
        return _addMonths(date, 6);
      case 'yearly':
        return _addMonths(date, 12);
      case 'monthly':
      default:
        return _addMonths(date, 1);
    }
  }

  DateTime _addMonths(DateTime date, int months) {
    final targetMonth = date.month - 1 + months;
    final year = date.year + targetMonth ~/ 12;
    final month = targetMonth % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, date.day.clamp(1, lastDay));
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({required this.item, required this.onTap});

  final RecurringTransaction item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == 'income';
    final color = isIncome
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.description,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        _StatusChip(isActive: item.isActive),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_frequencyLabel(item.frequency)} • Próxima: '
                      '${DateFormat('dd/MM/yyyy').format(item.nextOccurrence)}',
                    ),
                    if (item.endDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Até ${DateFormat('dd/MM/yyyy').format(item.endDate!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      _formatCurrency(item.amountCents),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.more_vert),
            ],
          ),
        ),
      ),
    );
  }

  static String _frequencyLabel(String value) {
    const labels = {
      'daily': 'Diária',
      'weekly': 'Semanal',
      'biweekly': 'Quinzenal',
      'monthly': 'Mensal',
      'bimonthly': 'Bimestral',
      'quarterly': 'Trimestral',
      'semiannual': 'Semestral',
      'yearly': 'Anual',
    };
    return labels[value] ?? value;
  }

  static String _formatCurrency(int cents) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(cents / 100);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.orange).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Ativa' : 'Pausada',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: isActive ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_repeat_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma recorrência cadastrada',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cadastre salários, aluguel, assinaturas e outros lançamentos repetitivos.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
