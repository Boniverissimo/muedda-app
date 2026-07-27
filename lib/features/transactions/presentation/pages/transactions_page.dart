import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/muedda_theme_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/ledger_entries_providers.dart';
import 'transaction_form_page.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _searchController = TextEditingController();

  String _searchText = '';
  String _selectedType = 'all';
  String _selectedStatus = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(ledgerEntriesStreamProvider);

    return Scaffold(
      backgroundColor: context.mueddaColors.canvas,
      appBar: AppBar(
        toolbarHeight: 88,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: context.mueddaColors.canvas,
        titleSpacing: AppSpacing.lg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lançamentos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.mueddaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Acompanhe todas as movimentações',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.mueddaColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: IconButton.filledTonal(
              tooltip: 'Limpar filtros',
              onPressed: _hasActiveFilters ? _clearFilters : null,
              icon: const Icon(Icons.filter_alt_off_outlined),
            ),
          ),
        ],
      ),
      body: entriesAsync.when(
        data: _buildContent,
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return _ErrorView(
            message: error.toString(),
            onRetry: () {
              ref.invalidate(ledgerEntriesStreamProvider);
            },
          );
        },
      ),
    );
  }

  bool get _hasActiveFilters {
    return _searchText.isNotEmpty ||
        _selectedType != 'all' ||
        _selectedStatus != 'all';
  }

  Widget _buildContent(List<LedgerEntry> entries) {
    final filteredEntries = _filterEntries(entries);

    final incomeCents = filteredEntries
        .where((entry) => entry.type == 'income' && entry.isPaid)
        .fold<int>(0, (total, entry) => total + entry.amountCents);

    final expenseCents = filteredEntries
        .where((entry) => entry.type == 'expense' && entry.isPaid)
        .fold<int>(0, (total, entry) => total + entry.amountCents);

    final groupedEntries = _groupEntriesByDate(filteredEntries);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ledgerEntriesStreamProvider);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildSearchField(),
                  const SizedBox(height: AppSpacing.md),
                  _buildTypeFilters(),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatusFilters(),
                  const SizedBox(height: AppSpacing.lg),
                  _TransactionsSummary(
                    incomeCents: incomeCents,
                    expenseCents: expenseCents,
                    entriesCount: filteredEntries.length,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          if (filteredEntries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _FilteredEmptyView(
                hasFilters: _hasActiveFilters,
                onClearFilters: _clearFilters,
              ),
            )
          else
            ..._buildGroupedSlivers(groupedEntries),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged: (value) {
        setState(() {
          _searchText = value.trim().toLowerCase();
        });
      },
      decoration: InputDecoration(
        hintText: 'Pesquisar lançamento',
        filled: true,
        fillColor: context.mueddaColors.surface,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchText.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar pesquisa',
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _searchText = '';
                  });
                },
                icon: const Icon(Icons.close),
              ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: context.mueddaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTypeFilters() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        segments: const [
          ButtonSegment<String>(value: 'all', label: Text('Todos')),
          ButtonSegment<String>(value: 'income', label: Text('Receitas')),
          ButtonSegment<String>(value: 'expense', label: Text('Despesas')),
          ButtonSegment<String>(
            value: 'transfer',
            label: Text('Transferências'),
          ),
        ],
        selected: {_selectedType},
        showSelectedIcon: false,
        onSelectionChanged: (selection) {
          setState(() {
            _selectedType = selection.first;
          });
        },
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Todos os status'),
            selected: _selectedStatus == 'all',
            onSelected: (_) {
              setState(() {
                _selectedStatus = 'all';
              });
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            label: const Text('Concluídos'),
            selected: _selectedStatus == 'paid',
            onSelected: (_) {
              setState(() {
                _selectedStatus = 'paid';
              });
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            label: const Text('Pendentes'),
            selected: _selectedStatus == 'pending',
            onSelected: (_) {
              setState(() {
                _selectedStatus = 'pending';
              });
            },
          ),
        ],
      ),
    );
  }

  List<LedgerEntry> _filterEntries(List<LedgerEntry> entries) {
    final filtered = entries.where((entry) {
      final matchesSearch =
          _searchText.isEmpty ||
          entry.description.toLowerCase().contains(_searchText);

      final matchesType = _selectedType == 'all' || entry.type == _selectedType;

      final matchesStatus = switch (_selectedStatus) {
        'paid' => entry.isPaid,
        'pending' => !entry.isPaid,
        _ => true,
      };

      return matchesSearch && matchesType && matchesStatus;
    }).toList();

    filtered.sort(
      (first, second) => second.occurredAt.compareTo(first.occurredAt),
    );

    return filtered;
  }

  Map<DateTime, List<LedgerEntry>> _groupEntriesByDate(
    List<LedgerEntry> entries,
  ) {
    final grouped = <DateTime, List<LedgerEntry>>{};

    for (final entry in entries) {
      final date = DateTime(
        entry.occurredAt.year,
        entry.occurredAt.month,
        entry.occurredAt.day,
      );

      grouped.putIfAbsent(date, () => []).add(entry);
    }

    return grouped;
  }

  List<Widget> _buildGroupedSlivers(
    Map<DateTime, List<LedgerEntry>> groupedEntries,
  ) {
    final widgets = <Widget>[];

    for (final group in groupedEntries.entries) {
      widgets.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: _DateHeader(date: group.key, entries: group.value),
          ),
        ),
      );

      widgets.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList.separated(
            itemCount: group.value.length,
            separatorBuilder: (_, _) {
              return const SizedBox(height: AppSpacing.sm);
            },
            itemBuilder: (context, index) {
              final entry = group.value[index];

              return _TransactionCard(
                entry: entry,
                onTap: () {
                  _openEditTransaction(entry);
                },
                onEdit: () {
                  _openEditTransaction(entry);
                },
                onDelete: () {
                  _confirmDelete(entry);
                },
              );
            },
          ),
        ),
      );

      widgets.add(
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
      );
    }

    return widgets;
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _searchText = '';
      _selectedType = 'all';
      _selectedStatus = 'all';
    });
  }

  Future<void> _openNewTransaction() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TransactionFormPage()),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transação cadastrada com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openEditTransaction(LedgerEntry entry) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TransactionFormPage(entry: entry)),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transação atualizada com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(LedgerEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.delete_outline),
          title: const Text('Excluir lançamento'),
          content: Text(
            'Deseja excluir o lançamento "${entry.description}"?\n\n'
            'Essa ação não poderá ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final repository = ref.read(ledgerEntriesRepositoryProvider);

      await repository.deleteEntry(entry.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lançamento excluído.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível excluir: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _TransactionsSummary extends StatelessWidget {
  const _TransactionsSummary({
    required this.incomeCents,
    required this.expenseCents,
    required this.entriesCount,
  });

  final int incomeCents;
  final int expenseCents;
  final int entriesCount;

  @override
  Widget build(BuildContext context) {
    final balanceCents = incomeCents - expenseCents;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Receitas',
                value: _formatCurrency(incomeCents),
                icon: Icons.south_west_rounded,
                color: AppColors.income,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SummaryCard(
                title: 'Despesas',
                value: _formatCurrency(expenseCents),
                icon: Icons.north_east_rounded,
                color: AppColors.expense,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.mueddaColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.mueddaColors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: balanceCents >= 0 ? AppColors.income : AppColors.expense,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resultado filtrado',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.mueddaColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(balanceCents),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: balanceCents >= 0
                            ? AppColors.income
                            : AppColors.expense,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$entriesCount ${entriesCount == 1 ? 'lançamento' : 'lançamentos'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.mueddaColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatCurrency(int cents) {
    final isNegative = cents < 0;
    final absoluteCents = cents.abs();

    final value = absoluteCents / 100;
    final parts = value.toStringAsFixed(2).split('.');

    final integerPart = parts.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    final formatted = 'R\$ $integerPart,${parts.last}';

    return isNegative ? '- $formatted' : formatted;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.mueddaColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.mueddaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.mueddaColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date, required this.entries});

  final DateTime date;
  final List<LedgerEntry> entries;

  @override
  Widget build(BuildContext context) {
    final totalCents = entries.fold<int>(0, (total, entry) {
      if (!entry.isPaid || entry.type == 'transfer') {
        return total;
      }

      if (entry.type == 'income') {
        return total + entry.amountCents;
      }

      return total - entry.amountCents;
    });

    return Row(
      children: [
        Expanded(
          child: Text(
            _formattedDateLabel(date),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          _formatSignedCurrency(totalCents),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: totalCents >= 0 ? AppColors.income : AppColors.expense,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formattedDateLabel(DateTime date) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final yesterday = normalizedToday.subtract(const Duration(days: 1));

    if (date == normalizedToday) {
      return 'Hoje';
    }

    if (date == yesterday) {
      return 'Ontem';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatSignedCurrency(int cents) {
    final value = cents.abs() / 100;
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');

    if (cents > 0) {
      return '+ R\$ $formatted';
    }

    if (cents < 0) {
      return '- R\$ $formatted';
    }

    return 'R\$ 0,00';
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.entry,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final LedgerEntry entry;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  bool get _isIncome => entry.type == 'income';

  bool get _isTransfer => entry.type == 'transfer';

  Color _valueColor() {
    if (_isIncome) {
      return AppColors.income;
    }

    if (_isTransfer) {
      return AppColors.primary;
    }

    return AppColors.expense;
  }

  IconData _icon() {
    if (_isIncome) {
      return Icons.south_west_rounded;
    }

    if (_isTransfer) {
      return Icons.swap_horiz_rounded;
    }

    return Icons.north_east_rounded;
  }

  String _typeLabel() {
    if (_isIncome) {
      return 'Receita';
    }

    if (_isTransfer) {
      return 'Transferência';
    }

    return 'Despesa';
  }

  String _formattedAmount() {
    final value = entry.amountCents / 100;
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');

    if (_isIncome) {
      return '+ R\$ $formatted';
    }

    if (_isTransfer) {
      return 'R\$ $formatted';
    }

    return '- R\$ $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.mueddaColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.mueddaColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _valueColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon(), color: _valueColor()),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          _typeLabel(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: context.mueddaColors.textSecondary),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.mueddaColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.isPaid ? 'Concluído' : 'Pendente',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: entry.isPaid
                                    ? context.mueddaColors.textSecondary
                                    : AppColors.expense,
                                fontWeight: entry.isPaid
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formattedAmount(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _valueColor(),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 32,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      tooltip: 'Opções',
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) {
                        return const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined),
                                SizedBox(width: 12),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline),
                                SizedBox(width: 12),
                                Text('Excluir'),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilteredEmptyView extends StatelessWidget {
  const _FilteredEmptyView({
    required this.hasFilters,
    required this.onClearFilters,
  });

  final bool hasFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_outlined,
              size: 72,
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              hasFilters ? 'Nenhum resultado encontrado' : 'Nenhum lançamento',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasFilters
                  ? 'Tente alterar a pesquisa ou os filtros.'
                  : 'Cadastre sua primeira receita, despesa ou transferência.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: context.mueddaColors.textSecondary),
            ),
            if (hasFilters) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Limpar filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Não foi possível carregar os lançamentos.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
