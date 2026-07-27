import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/components/muedda_back_button.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/budgets_providers.dart';
import '../../../../core/providers/categories_providers.dart';
import '../../../../core/providers/ledger_entries_providers.dart';
import '../../models/category_budget.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsControllerProvider);
    final categoriesAsync = ref.watch(expenseCategoriesStreamProvider);
    final entriesAsync = ref.watch(ledgerEntriesStreamProvider);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: const MueddaBackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Orçamentos', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            Text('Controle seus limites mensais', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () {
              ref.read(budgetsControllerProvider.notifier).load();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () async {
          final categories =
              categoriesAsync.asData?.value ?? const <Category>[];
          if (categories.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cadastre uma categoria de despesa primeiro.'),
              ),
            );
            return;
          }

          await _showBudgetDialog(context, ref, categories: categories);
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo orçamento'),
      ),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                const Text('Não foi possível carregar os orçamentos.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    ref.read(budgetsControllerProvider.notifier).load();
                  },
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (budgets) {
          final categories =
              categoriesAsync.asData?.value ?? const <Category>[];
          final entries = entriesAsync.asData?.value ?? const <LedgerEntry>[];
          final now = DateTime.now();
          final monthExpenses = entries.where(
            (entry) =>
                entry.type == 'expense' &&
                entry.isPaid &&
                entry.occurredAt.year == now.year &&
                entry.occurredAt.month == now.month,
          );

          if (budgets.isEmpty) {
            return const _EmptyBudgets();
          }

          final items =
              budgets.map((budget) {
                final category = categories
                    .where((item) => item.id == budget.categoryId)
                    .firstOrNull;
                final spentCents = monthExpenses
                    .where((entry) => entry.categoryId == budget.categoryId)
                    .fold<int>(0, (total, entry) => total + entry.amountCents);
                return _BudgetViewData(
                  budget: budget,
                  category: category,
                  spentCents: spentCents,
                );
              }).toList()..sort((a, b) {
                final aName = a.category?.name ?? '';
                final bName = b.category?.name ?? '';
                return aName.compareTo(bName);
              });

          final totalLimit = items
              .where((item) => item.budget.isActive)
              .fold<int>(
                0,
                (total, item) => total + item.budget.monthlyLimitCents,
              );
          final totalSpent = items
              .where((item) => item.budget.isActive)
              .fold<int>(0, (total, item) => total + item.spentCents);
          final totalProgress = totalLimit == 0 ? 0.0 : totalSpent / totalLimit;

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(budgetsControllerProvider.notifier).load();
              ref.invalidate(ledgerEntriesStreamProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                _OverallBudgetCard(
                  spentCents: totalSpent,
                  limitCents: totalLimit,
                  progress: totalProgress,
                  currency: currency,
                ),
                const SizedBox(height: 16),
                for (final item in items) ...[
                  _BudgetCard(
                    data: item,
                    currency: currency,
                    onEdit: () => _showBudgetDialog(
                      context,
                      ref,
                      categories: categories,
                      current: item.budget,
                    ),
                    onToggle: () => ref
                        .read(budgetsControllerProvider.notifier)
                        .toggle(item.budget),
                    onDelete: () => _deleteBudget(
                      context,
                      ref,
                      item.budget,
                      item.category?.name ?? 'esta categoria',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteBudget(
    BuildContext context,
    WidgetRef ref,
    CategoryBudget budget,
    String categoryName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir orçamento?'),
        content: Text('O orçamento de $categoryName será removido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(budgetsControllerProvider.notifier)
          .remove(budget.categoryId);
    }
  }

  Future<void> _showBudgetDialog(
    BuildContext context,
    WidgetRef ref, {
    required List<Category> categories,
    CategoryBudget? current,
  }) async {
    var selectedCategoryId = current?.categoryId ?? categories.first.id;
    var warningPercent = current?.warningPercent ?? 80;
    final amountController = TextEditingController(
      text: current == null
          ? ''
          : (current.monthlyLimitCents / 100).toStringAsFixed(2),
    );

    final result = await showDialog<CategoryBudget>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(current == null ? 'Novo orçamento' : 'Editar orçamento'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: current == null
                      ? (value) {
                          if (value != null) {
                            setState(() => selectedCategoryId = value);
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Limite mensal',
                    prefixText: 'R\$ ',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: warningPercent,
                  decoration: const InputDecoration(
                    labelText: 'Avisar ao atingir',
                  ),
                  items: const [70, 80, 90, 100]
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value%'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => warningPercent = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final normalized = amountController.text
                    .trim()
                    .replaceAll('.', '')
                    .replaceAll(',', '.');
                final amount = double.tryParse(normalized);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe um limite válido.')),
                  );
                  return;
                }

                Navigator.pop(
                  context,
                  CategoryBudget(
                    categoryId: selectedCategoryId,
                    monthlyLimitCents: (amount * 100).round(),
                    warningPercent: warningPercent,
                    isActive: current?.isActive ?? true,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    amountController.dispose();

    if (result != null) {
      await ref.read(budgetsControllerProvider.notifier).save(result);
    }
  }
}

class _EmptyBudgets extends StatelessWidget {
  const _EmptyBudgets();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum orçamento cadastrado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Defina limites mensais por categoria para acompanhar seus gastos.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallBudgetCard extends StatelessWidget {
  const _OverallBudgetCard({
    required this.spentCents,
    required this.limitCents,
    required this.progress,
    required this.currency,
  });

  final int spentCents;
  final int limitCents;
  final double progress;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final color = _progressColor(context, progress);
    final remaining = limitCents - spentCents;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.donut_large_rounded, color: Theme.of(context).colorScheme.onPrimary),
                const SizedBox(width: 8),
                Text(
                  'Orçamento geral do mês',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${(progress * 100).round()}%', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 10,
              color: Theme.of(context).colorScheme.onPrimary,
              backgroundColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            Text(
              '${currency.format(spentCents / 100)} de ${currency.format(limitCents / 100)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              remaining >= 0
                  ? '${currency.format(remaining / 100)} disponíveis'
                  : '${currency.format((-remaining) / 100)} acima do limite',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.82)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.data,
    required this.currency,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final _BudgetViewData data;
  final NumberFormat currency;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final budget = data.budget;
    final progress = budget.monthlyLimitCents == 0
        ? 0.0
        : data.spentCents / budget.monthlyLimitCents;
    final color = _progressColor(context, progress);
    final remaining = budget.monthlyLimitCents - data.spentCents;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Text(
                    (data.category?.name ?? '?').characters.first.toUpperCase(),
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.category?.name ?? 'Categoria removida',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: budget.isActive ? color.withValues(alpha: 0.10) : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          budget.isActive ? 'Ativo' : 'Pausado',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: budget.isActive ? color : null, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        return;
                      case 'toggle':
                        onToggle();
                        return;
                      case 'delete':
                        onDelete();
                        return;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(budget.isActive ? 'Pausar' : 'Ativar'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Excluir'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Opacity(
              opacity: budget.isActive ? 1 : 0.45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 8,
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${currency.format(data.spentCents / 100)} / ${currency.format(budget.monthlyLimitCents / 100)}',
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remaining >= 0
                        ? 'Restam ${currency.format(remaining / 100)}'
                        : 'Ultrapassou ${currency.format((-remaining) / 100)}',
                  ),
                  if (progress * 100 >= budget.warningPercent) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            progress >= 1
                                ? 'O limite desta categoria foi ultrapassado.'
                                : 'A categoria atingiu o nível de alerta de ${budget.warningPercent}%.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetViewData {
  const _BudgetViewData({
    required this.budget,
    required this.category,
    required this.spentCents,
  });

  final CategoryBudget budget;
  final Category? category;
  final int spentCents;
}

Color _progressColor(BuildContext context, double progress) {
  if (progress >= 1) {
    return Theme.of(context).colorScheme.error;
  }
  if (progress >= 0.9) {
    return Colors.deepOrange;
  }
  if (progress >= 0.7) {
    return Colors.amber.shade700;
  }
  return Colors.green;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
