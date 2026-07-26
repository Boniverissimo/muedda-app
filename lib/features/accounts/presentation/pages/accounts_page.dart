import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/accounts_providers.dart';

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contas')),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(child: Text('Nenhuma conta cadastrada.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            separatorBuilder: (context, index) {
              return const SizedBox(height: 8);
            },
            itemBuilder: (context, index) {
              final account = accounts[index];

              return Card(
                child: ListTile(
                  onTap: () {
                    _showAccountOptions(
                      context: context,
                      ref: ref,
                      account: account,
                    );
                  },
                  leading: const CircleAvatar(
                    child: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  title: Text(account.name),
                  subtitle: Text(
                    account.isActive ? 'Conta ativa' : 'Conta inativa',
                  ),
                  trailing: Text(_formatCurrency(account.initialBalanceCents)),
                ),
              );
            },
          );
        },
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return Center(child: Text('Erro ao carregar contas: $error'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'accounts_fab',
        onPressed: () {
          _showAccountDialog(context: context, ref: ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova conta'),
      ),
    );
  }

  Future<void> _showAccountOptions({
    required BuildContext context,
    required WidgetRef ref,
    required Account account,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();

                  _showAccountDialog(
                    context: context,
                    ref: ref,
                    account: account,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Excluir'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();

                  _confirmDeleteAccount(
                    context: context,
                    ref: ref,
                    account: account,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancelar'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAccountDialog({
    required BuildContext context,
    required WidgetRef ref,
    Account? account,
  }) async {
    final isEditing = account != null;

    final nameController = TextEditingController(text: account?.name ?? '');

    final balanceController = TextEditingController(
      text: account == null
          ? ''
          : _formatEditableCurrency(account.initialBalanceCents),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar conta' : 'Nova conta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da conta',
                  hintText: 'Ex.: Conta corrente',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Saldo inicial',
                  prefixText: 'R\$ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe o nome da conta.')),
                  );
                  return;
                }

                final balanceCents = _parseCurrencyToCents(
                  balanceController.text,
                );

                final repository = ref.read(accountsRepositoryProvider);

                if (isEditing) {
                  await repository.updateAccount(
                    id: account.id,
                    name: name,
                    initialBalanceCents: balanceCents,
                  );
                } else {
                  await repository.createAccount(
                    name: name,
                    initialBalanceCents: balanceCents,
                  );
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(isEditing ? 'Atualizar' : 'Salvar'),
            ),
          ],
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));

    nameController.dispose();
    balanceController.dispose();
  }

  Future<void> _confirmDeleteAccount({
    required BuildContext context,
    required WidgetRef ref,
    required Account account,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir conta'),
          content: Text('Deseja realmente excluir a conta "${account.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final repository = ref.read(accountsRepositoryProvider);

    await repository.deleteAccount(account.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta excluída com sucesso.')),
      );
    }
  }

  static int _parseCurrencyToCents(String value) {
    final normalized = value.replaceAll('.', '').replaceAll(',', '.').trim();

    final parsed = double.tryParse(normalized) ?? 0;

    return (parsed * 100).round();
  }

  static String _formatCurrency(int valueInCents) {
    final value = valueInCents / 100;

    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static String _formatEditableCurrency(int valueInCents) {
    final value = valueInCents / 100;

    return value.toStringAsFixed(2).replaceAll('.', ',');
  }
}
