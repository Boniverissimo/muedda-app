import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/accounts_providers.dart';
import '../../../../core/providers/credit_cards_providers.dart';

class CreditCardFormDialog extends ConsumerStatefulWidget {
  const CreditCardFormDialog({super.key, this.creditCard});

  final CreditCard? creditCard;

  @override
  ConsumerState<CreditCardFormDialog> createState() =>
      _CreditCardFormDialogState();
}

class _CreditCardFormDialogState extends ConsumerState<CreditCardFormDialog> {
  static const List<String> _availableColors = [
    '#1F6E5A',
    '#5B2E90',
    '#2F63B8',
    '#1F2937',
    '#C2414B',
    '#C77700',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _limitController;
  late final TextEditingController _closingDayController;
  late final TextEditingController _dueDayController;

  int? _selectedAccountId;
  late String _selectedColor;
  late bool _isActive;
  bool _isSaving = false;

  bool get _isEditing => widget.creditCard != null;

  @override
  void initState() {
    super.initState();

    final card = widget.creditCard;
    _nameController = TextEditingController(text: card?.name ?? '');
    _limitController = TextEditingController(
      text: card == null ? '' : _formatEditableCurrency(card.limitCents),
    );
    _closingDayController = TextEditingController(
      text: card?.closingDay.toString() ?? '',
    );
    _dueDayController = TextEditingController(
      text: card?.dueDay.toString() ?? '',
    );
    _selectedAccountId = card?.accountId;
    _selectedColor = _normalizeColor(card?.colorHex) ?? _availableColors.first;
    _isActive = card?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    _closingDayController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(activeAccountsStreamProvider);

    return AlertDialog(
      title: Text(_isEditing ? 'Editar cartão' : 'Novo cartão'),
      content: SizedBox(
        width: 480,
        child: accountsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) =>
              Text('Não foi possível carregar as contas: $error'),
          data: (accounts) {
            if (accounts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Cadastre pelo menos uma conta ativa antes de criar um cartão.',
                ),
              );
            }

            final accountExists = accounts.any(
              (account) => account.id == _selectedAccountId,
            );
            if (!accountExists) {
              _selectedAccountId = accounts.first.id;
            }

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nome do cartão',
                        hintText: 'Ex.: Cartão principal',
                        prefixIcon: Icon(Icons.credit_card_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome do cartão.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Conta vinculada',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      items: accounts
                          .map(
                            (account) => DropdownMenuItem<int>(
                              value: account.id,
                              child: Text(account.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _selectedAccountId = value;
                              });
                            },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione uma conta.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _limitController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Limite total',
                        prefixText: 'R\$ ',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      validator: (value) {
                        final cents = _parseCurrencyToCents(value ?? '');
                        if (cents <= 0) {
                          return 'Informe um limite maior que zero.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _closingDayController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Dia de fechamento',
                              prefixIcon: Icon(Icons.event_busy_outlined),
                            ),
                            validator: _validateDay,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _dueDayController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Dia de vencimento',
                              prefixIcon: Icon(Icons.event_available_outlined),
                            ),
                            validator: _validateDay,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Cor do cartão',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _availableColors
                          .map((hex) {
                            final isSelected = hex == _selectedColor;
                            return InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: _isSaving
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedColor = hex;
                                      });
                                    },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _colorFromHex(hex),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onSurface
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 20,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Cartão ativo'),
                        subtitle: Text(
                          _isActive
                              ? 'Disponível para novos lançamentos'
                              : 'Oculto das seleções de cartão',
                        ),
                        value: _isActive,
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _isSaving || accountsAsync.valueOrNull?.isEmpty == true
              ? null
              : _save,
          icon: _isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_isEditing ? 'Atualizar' : 'Salvar'),
        ),
      ],
    );
  }

  String? _validateDay(String? value) {
    final day = int.tryParse(value?.trim() ?? '');
    if (day == null || day < 1 || day > 31) {
      return 'Use um dia entre 1 e 31.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final accountId = _selectedAccountId;
    if (accountId == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(creditCardsRepositoryProvider);
      final card = widget.creditCard;

      if (card == null) {
        await repository.createCreditCard(
          name: _nameController.text.trim(),
          accountId: accountId,
          closingDay: int.parse(_closingDayController.text.trim()),
          dueDay: int.parse(_dueDayController.text.trim()),
          limitCents: _parseCurrencyToCents(_limitController.text),
          colorHex: _selectedColor,
        );
      } else {
        await repository.updateCreditCard(
          id: card.id,
          name: _nameController.text.trim(),
          accountId: accountId,
          closingDay: int.parse(_closingDayController.text.trim()),
          dueDay: int.parse(_dueDayController.text.trim()),
          limitCents: _parseCurrencyToCents(_limitController.text),
          colorHex: _selectedColor,
          isActive: _isActive,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o cartão: $error')),
      );
    }
  }

  static int _parseCurrencyToCents(String value) {
    var normalized = value.trim().replaceAll('R\$', '').replaceAll(' ', '');

    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }

    final parsed = double.tryParse(normalized) ?? 0;
    return (parsed * 100).round();
  }

  static String _formatEditableCurrency(int valueInCents) {
    return (valueInCents / 100).toStringAsFixed(2).replaceAll('.', ',');
  }

  static String? _normalizeColor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final normalized = value.trim().toUpperCase();
    return normalized.startsWith('#') ? normalized : '#$normalized';
  }

  static Color _colorFromHex(String hex) {
    final cleanHex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleanHex', radix: 16));
  }
}
