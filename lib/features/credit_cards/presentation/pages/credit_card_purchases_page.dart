import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/components/muedda_back_button.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/categories_providers.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/providers/ledger_entries_providers.dart';

class CreditCardPurchasesPage extends ConsumerStatefulWidget {
  const CreditCardPurchasesPage({super.key, required this.creditCard});

  final CreditCard creditCard;

  @override
  ConsumerState<CreditCardPurchasesPage> createState() =>
      _CreditCardPurchasesPageState();
}

class _CreditCardPurchasesPageState
    extends ConsumerState<CreditCardPurchasesPage> {
  late DateTime _selectedInvoiceMonth;
  bool _payingInvoice = false;

  CreditCard get creditCard => widget.creditCard;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedInvoiceMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(
      entriesByCreditCardStreamProvider(creditCard.id),
    );
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final categoryNames = <int, String>{
      for (final category in categoriesAsync.valueOrNull ?? const <Category>[])
        category.id: category.name,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: const MueddaBackButton(),
        title: Text(creditCard.name),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text('Erro ao carregar compras: $error'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(
                    entriesByCreditCardStreamProvider(creditCard.id),
                  ),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (entries) {
          final pendingCents = entries
              .where((entry) => !entry.isPaid)
              .fold<int>(0, (sum, entry) => sum + entry.amountCents);
          final availableCents = creditCard.limitCents - pendingCents;
          final invoiceEntries =
              entries
                  .where(
                    (entry) => _isInInvoiceMonth(entry, _selectedInvoiceMonth),
                  )
                  .toList(growable: false)
                ..sort((a, b) {
                  final aDate = a.dueDate ?? a.occurredAt;
                  final bDate = b.dueDate ?? b.occurredAt;
                  return aDate.compareTo(bDate);
                });
          final invoiceTotalCents = invoiceEntries.fold<int>(
            0,
            (sum, entry) => sum + entry.amountCents,
          );
          final invoicePendingCents = invoiceEntries
              .where((entry) => !entry.isPaid)
              .fold<int>(0, (sum, entry) => sum + entry.amountCents);
          final invoicePaidCents = invoiceTotalCents - invoicePendingCents;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(entriesByCreditCardStreamProvider(creditCard.id));
              await ref.read(
                entriesByCreditCardStreamProvider(creditCard.id).future,
              );
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                _LimitSummary(
                  limitCents: creditCard.limitCents,
                  pendingCents: pendingCents,
                  availableCents: availableCents,
                ),
                const SizedBox(height: 20),
                _InvoiceMonthSelector(
                  selectedMonth: _selectedInvoiceMonth,
                  onPrevious: () => _changeInvoiceMonth(-1),
                  onNext: () => _changeInvoiceMonth(1),
                  onCurrent: _goToCurrentMonth,
                ),
                const SizedBox(height: 12),
                _InvoiceSummary(
                  totalCents: invoiceTotalCents,
                  paidCents: invoicePaidCents,
                  pendingCents: invoicePendingCents,
                  dueDay: creditCard.dueDay,
                  hasEntries: invoiceEntries.isNotEmpty,
                  isPaying: _payingInvoice,
                  onPay: invoicePendingCents > 0
                      ? () => _payInvoice(invoiceEntries)
                      : null,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lançamentos da fatura',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text('${invoiceEntries.length} item(ns)'),
                  ],
                ),
                const SizedBox(height: 12),
                if (invoiceEntries.isEmpty)
                  const _EmptyInvoice()
                else
                  for (final entry in invoiceEntries) ...[
                    _PurchaseTile(
                      entry: entry,
                      categoryName: entry.categoryId == null
                          ? 'Sem categoria'
                          : categoryNames[entry.categoryId!] ?? 'Categoria',
                      onTap: () => _showEntryOptions(context, ref, entry),
                    ),
                    const SizedBox(height: 10),
                  ],
                if (entries.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Histórico completo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: const Text(
                      'Todas as compras e parcelas do cartão',
                    ),
                    children: [
                      for (final entry in entries) ...[
                        _PurchaseTile(
                          entry: entry,
                          categoryName: entry.categoryId == null
                              ? 'Sem categoria'
                              : categoryNames[entry.categoryId!] ?? 'Categoria',
                          onTap: () => _showEntryOptions(context, ref, entry),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'credit_card_purchase_fab_${creditCard.id}',
        onPressed: () =>
            context.push(AppRouter.newTransaction, extra: creditCard),
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('Nova transação'),
      ),
    );
  }

  bool _isInInvoiceMonth(LedgerEntry entry, DateTime month) {
    final dueDate = entry.dueDate ?? entry.occurredAt;
    return dueDate.year == month.year && dueDate.month == month.month;
  }

  void _changeInvoiceMonth(int months) {
    setState(() {
      _selectedInvoiceMonth = DateTime(
        _selectedInvoiceMonth.year,
        _selectedInvoiceMonth.month + months,
      );
    });
  }

  void _goToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _selectedInvoiceMonth = DateTime(now.year, now.month);
    });
  }

  Future<void> _payInvoice(List<LedgerEntry> invoiceEntries) async {
    final pendingEntries = invoiceEntries
        .where((entry) => !entry.isPaid)
        .toList(growable: false);
    if (pendingEntries.isEmpty) {
      return;
    }

    final totalCents = pendingEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.amountCents,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pagar fatura'),
        content: Text(
          'Confirmar o pagamento de ${_formatMoney(totalCents)} da fatura de '
          '${DateFormat("MMMM 'de' yyyy", 'pt_BR').format(_selectedInvoiceMonth)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar pagamento'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _payingInvoice = true);
    try {
      final repository = ref.read(ledgerEntriesRepositoryProvider);
      for (final entry in pendingEntries) {
        await repository.markAsPaid(entry.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fatura paga com sucesso.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível pagar a fatura: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _payingInvoice = false);
      }
    }
  }

  Future<void> _showEntryOptions(
    BuildContext context,
    WidgetRef ref,
    LedgerEntry entry,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(
                entry.isPaid ? Icons.undo_outlined : Icons.check_circle_outline,
              ),
              title: Text(
                entry.isPaid ? 'Marcar como pendente' : 'Marcar como paga',
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final repository = ref.read(ledgerEntriesRepositoryProvider);
                if (entry.isPaid) {
                  await repository.markAsPending(entry.id);
                } else {
                  await repository.markAsPaid(entry.id);
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Excluir lançamento',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmDelete(context, ref, entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    LedgerEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir lançamento'),
        content: Text('Deseja excluir "${entry.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(ledgerEntriesRepositoryProvider).deleteEntry(entry.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lançamento excluído.')));
      }
    }
  }
}

class _InvoiceMonthSelector extends StatelessWidget {
  const _InvoiceMonthSelector({
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
  });

  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Fatura anterior',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: InkWell(
                onTap: onCurrent,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Text(
                        'Fatura',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _capitalize(
                          DateFormat(
                            "MMMM 'de' yyyy",
                            'pt_BR',
                          ).format(selectedMonth),
                        ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Próxima fatura',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceSummary extends StatelessWidget {
  const _InvoiceSummary({
    required this.totalCents,
    required this.paidCents,
    required this.pendingCents,
    required this.dueDay,
    required this.hasEntries,
    required this.isPaying,
    required this.onPay,
  });

  final int totalCents;
  final int paidCents;
  final int pendingCents;
  final int dueDay;
  final bool hasEntries;
  final bool isPaying;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final progress = totalCents <= 0
        ? 0.0
        : (paidCents / totalCents).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasEntries ? 'Total da fatura' : 'Fatura sem lançamentos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (hasEntries)
                  Chip(
                    avatar: Icon(
                      pendingCents == 0 ? Icons.check_circle : Icons.schedule,
                      size: 18,
                    ),
                    label: Text(pendingCents == 0 ? 'Paga' : 'Em aberto'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _formatMoney(totalCents),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text('Vencimento previsto no dia $dueDay'),
            if (hasEntries) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pago: ${_formatMoney(paidCents)}'),
                  Text('Pendente: ${_formatMoney(pendingCents)}'),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isPaying ? null : onPay,
                icon: isPaying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payments_outlined),
                label: Text(pendingCents == 0 ? 'Fatura paga' : 'Pagar fatura'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LimitSummary extends StatelessWidget {
  const _LimitSummary({
    required this.limitCents,
    required this.pendingCents,
    required this.availableCents,
  });

  final int limitCents;
  final int pendingCents;
  final int availableCents;

  @override
  Widget build(BuildContext context) {
    final usage = limitCents <= 0
        ? 0.0
        : (pendingCents / limitCents).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.76),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Limite disponível',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatMoney(availableCents),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: usage),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Usado: ${_formatMoney(pendingCents)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
                Text(
                  'Limite: ${_formatMoney(limitCents)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile({
    required this.entry,
    required this.categoryName,
    required this.onTap,
  });

  final LedgerEntry entry;
  final String categoryName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dueDate = entry.dueDate ?? entry.occurredAt;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.38),
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onTap: onTap,
        leading: CircleAvatar(
          child: Icon(entry.isPaid ? Icons.check : Icons.schedule),
        ),
        title: Text(entry.description),
        subtitle: Text(
          '$categoryName • Vence ${DateFormat('dd/MM/yyyy').format(dueDate)}\n'
          '${entry.isPaid ? 'Paga' : 'Pendente'}',
        ),
        isThreeLine: true,
        trailing: Text(
          _formatMoney(entry.amountCents),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _EmptyInvoice extends StatelessWidget {
  const _EmptyInvoice();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum lançamento nesta fatura',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Navegue entre os meses ou registre uma nova compra.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMoney(int cents) {
  return NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  ).format(cents / 100);
}

String _capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
