import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

import '../../../../core/ui/components/muedda_back_button.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/ledger_entries_providers.dart';
import '../../../transactions/presentation/pages/transaction_form_page.dart';

enum _PeriodFilter { all, today, week, month, next30Days }

enum _StatusFilter { all, pending, overdue, completed }

class PayablesReceivablesPage extends ConsumerStatefulWidget {
  const PayablesReceivablesPage({super.key});

  @override
  ConsumerState<PayablesReceivablesPage> createState() =>
      _PayablesReceivablesPageState();
}

class _PayablesReceivablesPageState
    extends ConsumerState<PayablesReceivablesPage> {
  _PeriodFilter _period = _PeriodFilter.month;
  _StatusFilter _status = _StatusFilter.all;
  String _type = 'all';

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(ledgerEntriesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const MueddaBackButton(),
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Contas a pagar e receber',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        onPressed: _openNewEntry,
        icon: const Icon(Icons.add),
        label: const Text('Novo lançamento'),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text('Não foi possível carregar os vencimentos.\n$error'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(ledgerEntriesStreamProvider),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: _buildContent,
      ),
    );
  }

  Widget _buildContent(List<LedgerEntry> allEntries) {
    final entries =
        allEntries
            .where(
              (entry) =>
                  entry.dueDate != null &&
                  (entry.type == 'income' || entry.type == 'expense'),
            )
            .where(_matchesFilters)
            .toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    final today = _dateOnly(DateTime.now());
    final pendingPayables = allEntries
        .where((entry) {
          return entry.type == 'expense' &&
              entry.dueDate != null &&
              !entry.isPaid;
        })
        .fold<int>(0, (sum, entry) => sum + entry.amountCents);
    final pendingReceivables = allEntries
        .where((entry) {
          return entry.type == 'income' &&
              entry.dueDate != null &&
              !entry.isPaid;
        })
        .fold<int>(0, (sum, entry) => sum + entry.amountCents);
    final overdue = allEntries
        .where((entry) {
          final due = entry.dueDate;
          return due != null && !entry.isPaid && _dateOnly(due).isBefore(today);
        })
        .fold<int>(0, (sum, entry) => sum + entry.amountCents);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(ledgerEntriesStreamProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 112,
        ),
        children: [
          _SummaryGrid(
            pendingPayables: pendingPayables,
            pendingReceivables: pendingReceivables,
            overdue: overdue,
          ),
          const SizedBox(height: 18),
          _buildFilters(),
          const SizedBox(height: 18),
          Text(
            '${entries.length} ${entries.length == 1 ? 'vencimento' : 'vencimentos'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            const _EmptyState()
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DueEntryCard(
                  entry: entry,
                  onTogglePaid: () => _togglePaid(entry),
                  onEdit: () => _editEntry(entry),
                  onDuplicate: () => _duplicateEntry(entry),
                  onDelete: () => _deleteEntry(entry),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtros', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                prefixIcon: Icon(Icons.swap_vert),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Todos')),
                DropdownMenuItem(value: 'expense', child: Text('A pagar')),
                DropdownMenuItem(value: 'income', child: Text('A receber')),
              ],
              onChanged: (value) => setState(() => _type = value ?? 'all'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_PeriodFilter>(
              initialValue: _period,
              decoration: const InputDecoration(
                labelText: 'Período',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: _PeriodFilter.all,
                  child: Text('Todos'),
                ),
                DropdownMenuItem(
                  value: _PeriodFilter.today,
                  child: Text('Hoje'),
                ),
                DropdownMenuItem(
                  value: _PeriodFilter.week,
                  child: Text('Esta semana'),
                ),
                DropdownMenuItem(
                  value: _PeriodFilter.month,
                  child: Text('Este mês'),
                ),
                DropdownMenuItem(
                  value: _PeriodFilter.next30Days,
                  child: Text('Próximos 30 dias'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _period = value ?? _PeriodFilter.month),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusChip('Todos', _StatusFilter.all),
                _statusChip('Pendentes', _StatusFilter.pending),
                _statusChip('Vencidos', _StatusFilter.overdue),
                _statusChip('Concluídos', _StatusFilter.completed),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, _StatusFilter value) {
    return ChoiceChip(
      label: Text(label),
      selected: _status == value,
      onSelected: (_) => setState(() => _status = value),
    );
  }

  bool _matchesFilters(LedgerEntry entry) {
    if (_type != 'all' && entry.type != _type) return false;

    final due = _dateOnly(entry.dueDate!);
    final today = _dateOnly(DateTime.now());

    final matchesStatus = switch (_status) {
      _StatusFilter.all => true,
      _StatusFilter.pending => !entry.isPaid && !due.isBefore(today),
      _StatusFilter.overdue => !entry.isPaid && due.isBefore(today),
      _StatusFilter.completed => entry.isPaid,
    };
    if (!matchesStatus) return false;

    return switch (_period) {
      _PeriodFilter.all => true,
      _PeriodFilter.today => due == today,
      _PeriodFilter.week =>
        !due.isBefore(_startOfWeek(today)) &&
            due.isBefore(_startOfWeek(today).add(const Duration(days: 7))),
      _PeriodFilter.month => due.year == today.year && due.month == today.month,
      _PeriodFilter.next30Days =>
        !due.isBefore(today) &&
            !due.isAfter(today.add(const Duration(days: 30))),
    };
  }

  Future<void> _openNewEntry() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TransactionFormPage()),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lançamento criado com sucesso.')),
      );
    }
  }

  Future<void> _editEntry(LedgerEntry entry) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TransactionFormPage(entry: entry)),
    );
    if (updated == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lançamento atualizado.')));
    }
  }

  Future<void> _togglePaid(LedgerEntry entry) async {
    final repository = ref.read(ledgerEntriesRepositoryProvider);
    if (entry.isPaid) {
      await repository.markAsPending(entry.id);
    } else {
      await repository.markAsPaid(entry.id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            entry.isPaid
                ? 'Lançamento marcado como pendente.'
                : entry.type == 'income'
                ? 'Receita marcada como recebida.'
                : 'Despesa marcada como paga.',
          ),
        ),
      );
    }
  }

  Future<void> _duplicateEntry(LedgerEntry entry) async {
    final repository = ref.read(ledgerEntriesRepositoryProvider);
    await repository.createEntry(
      description: '${entry.description} (cópia)',
      amountCents: entry.amountCents,
      type: entry.type,
      accountId: entry.accountId,
      occurredAt: entry.occurredAt,
      destinationAccountId: entry.destinationAccountId,
      categoryId: entry.categoryId,
      creditCardId: entry.creditCardId,
      dueDate: entry.dueDate,
      isPaid: false,
      notes: entry.notes,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lançamento duplicado como pendente.')),
      );
    }
  }

  Future<void> _deleteEntry(LedgerEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir lançamento'),
        content: Text('Deseja excluir "${entry.description}"?'),
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

    await ref.read(ledgerEntriesRepositoryProvider).deleteEntry(entry.id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lançamento excluído.')));
    }
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.pendingPayables,
    required this.pendingReceivables,
    required this.overdue,
  });

  final int pendingPayables;
  final int pendingReceivables;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 760
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryCard(
              width: width,
              title: 'A pagar',
              value: _currency(pendingPayables),
              icon: Icons.north_east_rounded,
              color: Colors.red,
            ),
            _SummaryCard(
              width: width,
              title: 'A receber',
              value: _currency(pendingReceivables),
              icon: Icons.south_west_rounded,
              color: Colors.green,
            ),
            _SummaryCard(
              width: width,
              title: 'Vencidos',
              value: _currency(overdue),
              icon: Icons.warning_amber_rounded,
              color: Colors.orange,
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueEntryCard extends StatelessWidget {
  const _DueEntryCard({
    required this.entry,
    required this.onTogglePaid,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final LedgerEntry entry;
  final VoidCallback onTogglePaid;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final due = _dateOnly(entry.dueDate!);
    final today = _dateOnly(DateTime.now());
    final overdue = !entry.isPaid && due.isBefore(today);
    final color = entry.isPaid
        ? Colors.green
        : overdue
        ? Colors.red
        : Colors.orange;
    final status = entry.isPaid
        ? entry.type == 'income'
              ? 'Recebido'
              : 'Pago'
        : overdue
        ? 'Vencido'
        : 'Pendente';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Icon(
            entry.type == 'income'
                ? Icons.south_west_rounded
                : Icons.north_east_rounded,
          ),
        ),
        title: Text(entry.description),
        subtitle: Text(
          '${entry.type == 'income' ? 'A receber' : 'A pagar'} • '
          'Vence em ${_date(entry.dueDate!)} • $status',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currency(entry.amountCents),
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'toggle':
                    onTogglePaid();
                    break;
                  case 'edit':
                    onEdit();
                    break;
                  case 'duplicate':
                    onDuplicate();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    entry.isPaid
                        ? 'Marcar como pendente'
                        : entry.type == 'income'
                        ? 'Marcar como recebido'
                        : 'Marcar como pago',
                  ),
                ),
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Text('Duplicar'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Excluir')),
              ],
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum vencimento encontrado',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Crie uma receita ou despesa com data de vencimento, ou altere os filtros.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _startOfWeek(DateTime value) =>
    value.subtract(Duration(days: value.weekday - DateTime.monday));

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

String _currency(int cents) {
  final value = cents / 100;
  final text = value.toStringAsFixed(2).replaceAll('.', ',');
  final parts = text.split(',');
  final chars = parts.first.split('').reversed.toList();
  final grouped = <String>[];
  for (var index = 0; index < chars.length; index++) {
    if (index > 0 && index % 3 == 0) grouped.add('.');
    grouped.add(chars[index]);
  }
  return 'R\$ ${grouped.reversed.join()},${parts.last}';
}
