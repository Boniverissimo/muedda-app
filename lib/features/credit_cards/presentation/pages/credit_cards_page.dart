import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/accounts_providers.dart';
import '../../../../core/providers/credit_cards_providers.dart';
import '../widgets/credit_card_form_dialog.dart';

class CreditCardsPage extends ConsumerWidget {
  const CreditCardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(creditCardsStreamProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);

    final accountNames = <int, String>{
      for (final account in accountsAsync.valueOrNull ?? const <Account>[])
        account.id: account.name,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Cartões de crédito')),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(
          message: 'Erro ao carregar cartões: $error',
          onRetry: () => ref.invalidate(creditCardsStreamProvider),
        ),
        data: (cards) {
          if (cards.isEmpty) {
            return _EmptyState(onCreate: () => _openForm(context, ref));
          }

          final activeCount = cards.where((card) => card.isActive).length;
          final totalLimitCents = cards
              .where((card) => card.isActive)
              .fold<int>(0, (total, card) => total + card.limitCents);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(creditCardsStreamProvider);
              await ref.read(creditCardsStreamProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
              children: [
                _CardsSummary(
                  activeCount: activeCount,
                  totalCount: cards.length,
                  totalLimitCents: totalLimitCents,
                ),
                const SizedBox(height: 20),
                Text(
                  'Seus cartões',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final card in cards) ...[
                  _CreditCardTile(
                    card: card,
                    accountName:
                        accountNames[card.accountId] ?? 'Conta não encontrada',
                    onTap: () =>
                        _showOptions(context: context, ref: ref, card: card),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'credit_cards_fab',
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Novo cartão'),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    CreditCard? card,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return CreditCardFormDialog(creditCard: card);
      },
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            card == null
                ? 'Cartão cadastrado com sucesso.'
                : 'Cartão atualizado com sucesso.',
          ),
        ),
      );
    }
  }

  Future<void> _showOptions({
    required BuildContext context,
    required WidgetRef ref,
    required CreditCard card,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Ver compras e faturas'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  context.push(AppRouter.creditCardPurchases, extra: card);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar cartão'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _openForm(context, ref, card: card);
                },
              ),
              ListTile(
                leading: Icon(
                  card.isActive
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                title: Text(
                  card.isActive ? 'Desativar cartão' : 'Ativar cartão',
                ),
                onTap: () async {
                  Navigator.of(bottomSheetContext).pop();
                  await _toggleActive(context, ref, card);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Excluir cartão',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _confirmDelete(context, ref, card);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    CreditCard card,
  ) async {
    try {
      await ref
          .read(creditCardsRepositoryProvider)
          .updateCreditCard(id: card.id, isActive: !card.isActive);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              card.isActive
                  ? 'Cartão desativado com sucesso.'
                  : 'Cartão ativado com sucesso.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível alterar o cartão: $error')),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CreditCard card,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir cartão'),
          content: Text(
            'Deseja realmente excluir o cartão "${card.name}"? Essa ação não poderá ser desfeita.',
          ),
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
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(creditCardsRepositoryProvider).deleteCreditCard(card.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cartão excluído com sucesso.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível excluir o cartão: $error')),
        );
      }
    }
  }
}

class _CardsSummary extends StatelessWidget {
  const _CardsSummary({
    required this.activeCount,
    required this.totalCount,
    required this.totalLimitCents,
  });

  final int activeCount;
  final int totalCount;
  final int totalLimitCents;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.credit_card_outlined,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Limite total ativo',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatCurrency(totalLimitCents),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$activeCount/$totalCount ativos'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditCardTile extends StatelessWidget {
  const _CreditCardTile({
    required this.card,
    required this.accountName,
    required this.onTap,
  });

  final CreditCard card;
  final String accountName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = _colorFromHex(card.colorHex);
    final foregroundColor = _foregroundFor(cardColor);

    return Semantics(
      button: true,
      label: 'Abrir opções do cartão ${card.name}',
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: card.isActive ? 1 : 0.58,
          child: Container(
            width: double.infinity,
            height: 200,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: cardColor.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.credit_card, color: foregroundColor),
                    const Spacer(),
                    if (!card.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: foregroundColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Inativo',
                          style: TextStyle(
                            color: foregroundColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(Icons.more_horiz, color: foregroundColor),
                  ],
                ),
                const Spacer(),
                Text(
                  card.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  accountName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _CardInformation(
                        label: 'Limite',
                        value: _formatCurrency(card.limitCents),
                        foregroundColor: foregroundColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CardInformation(
                        label: 'Fechamento',
                        value: 'Dia ${card.closingDay}',
                        foregroundColor: foregroundColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CardInformation(
                        label: 'Vencimento',
                        value: 'Dia ${card.dueDay}',
                        foregroundColor: foregroundColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _colorFromHex(String? hex) {
    final normalized = (hex ?? '#1F6E5A').replaceFirst('#', '');
    final value = int.tryParse('FF$normalized', radix: 16);
    return value == null ? const Color(0xFF1F6E5A) : Color(value);
  }

  static Color _foregroundFor(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : const Color(0xFF17211E);
  }
}

class _CardInformation extends StatelessWidget {
  const _CardInformation({
    required this.label,
    required this.value,
    required this.foregroundColor,
  });

  final String label;
  final String value;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: foregroundColor.withValues(alpha: 0.68),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_off_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhum cartão cadastrado',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Cadastre seu primeiro cartão para controlar limite, fechamento e vencimento.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar cartão'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
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

String _formatCurrency(int valueInCents) {
  final value = valueInCents / 100;
  final parts = value.toStringAsFixed(2).split('.');
  final integerPart = parts.first;
  final decimalPart = parts.last;

  final buffer = StringBuffer();
  for (var index = 0; index < integerPart.length; index++) {
    if (index > 0 && (integerPart.length - index) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(integerPart[index]);
  }

  return 'R\$ ${buffer.toString()},$decimalPart';
}
