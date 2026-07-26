import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/accounts_providers.dart';
import '../../../../core/providers/categories_providers.dart';
import '../../../../core/providers/credit_cards_providers.dart';
import '../../../../core/providers/ledger_entries_providers.dart';
import '../../../../core/providers/recurring_transactions_providers.dart';

class NewTransactionPage extends ConsumerStatefulWidget {
  const NewTransactionPage({
    super.key,
    this.initialType = 'expense',
    this.initialCreditCardId,
    this.initialDescription,
    this.initialAmountCents,
    this.initialOccurredAt,
    this.initialCategoryId,
  });

  final String initialType;
  final int? initialCreditCardId;
  final String? initialDescription;
  final int? initialAmountCents;
  final DateTime? initialOccurredAt;
  final int? initialCategoryId;

  @override
  ConsumerState<NewTransactionPage> createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends ConsumerState<NewTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  late String _transactionType;

  int? _selectedAccountId;
  int? _selectedCategoryId;
  int? _selectedCreditCardId;
  int? _selectedDestinationAccountId;

  bool _isSaving = false;
  bool _isInstallmentPurchase = false;
  int _installments = 2;

  DateTime _occurredAt = DateTime.now();
  bool _isPaid = true;

  bool _isRecurring = false;
  String _recurrenceFrequency = 'monthly';
  DateTime? _recurrenceEndDate;
  bool _autoGenerateRecurrence = true;

  @override
  void initState() {
    super.initState();
    _transactionType = widget.initialType;
    _selectedCreditCardId = widget.initialCreditCardId;
    _selectedCategoryId = widget.initialCategoryId;
    _occurredAt = widget.initialOccurredAt ?? DateTime.now();

    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
    if (widget.initialAmountCents != null) {
      _amountController.text = _formatInitialAmount(widget.initialAmountCents!);
    }
  }

  String _formatInitialAmount(int amountCents) {
    final value = amountCents / 100;
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(activeAccountsStreamProvider);
    final creditCardsAsync = ref.watch(activeCreditCardsStreamProvider);

    final AsyncValue<List<Category>> categoriesAsync;

    if (_transactionType == 'income') {
      categoriesAsync = ref.watch(incomeCategoriesStreamProvider);
    } else if (_transactionType == 'expense' || _transactionType == 'card') {
      categoriesAsync = ref.watch(expenseCategoriesStreamProvider);
    } else {
      categoriesAsync = const AsyncData<List<Category>>(<Category>[]);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nova transação')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Tipo da transação'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'income',
                        label: Text('Receita'),
                        icon: Icon(Icons.south_west_rounded),
                      ),
                      ButtonSegment<String>(
                        value: 'expense',
                        label: Text('Despesa'),
                        icon: Icon(Icons.north_east_rounded),
                      ),
                      ButtonSegment<String>(
                        value: 'card',
                        label: Text('Cartão'),
                        icon: Icon(Icons.credit_card_rounded),
                      ),
                      ButtonSegment<String>(
                        value: 'transfer',
                        label: Text('Transferência'),
                        icon: Icon(Icons.swap_horiz_rounded),
                      ),
                    ],
                    selected: {_transactionType},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      setState(() {
                        _transactionType = selection.first;
                        _selectedCategoryId = null;
                        if (_transactionType != 'card') {
                          _selectedCreditCardId = null;
                        }
                        _selectedDestinationAccountId = null;
                        _isInstallmentPurchase = false;
                        _installments = 2;
                        if (_transactionType != 'income' &&
                            _transactionType != 'expense') {
                          _isRecurring = false;
                          _recurrenceEndDate = null;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const _FieldLabel('Descrição'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 150,
                  decoration: _inputDecoration(
                    hintText: _descriptionHint,
                    icon: Icons.edit_note_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe uma descrição.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Valor'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*[,.]?\d{0,2}'),
                    ),
                  ],
                  decoration: _inputDecoration(
                    hintText: '0,00',
                    icon: Icons.payments_outlined,
                    prefixText: 'R\$ ',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o valor.';
                    }

                    final amountCents = _parseAmountToCents(value);

                    if (amountCents == null || amountCents <= 0) {
                      return 'Informe um valor maior que zero.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_transactionType != 'card')
                  _buildAccountField(accountsAsync),
                if (_transactionType == 'transfer') ...[
                  const SizedBox(height: 16),
                  _buildDestinationAccountField(accountsAsync),
                ],
                if (_transactionType != 'transfer') ...[
                  const SizedBox(height: 16),
                  _buildCategoryField(categoriesAsync),
                ],
                if (_transactionType == 'card') ...[
                  const SizedBox(height: 16),
                  _buildCreditCardField(creditCardsAsync),
                  const SizedBox(height: 16),
                  _buildInstallmentFields(),
                ],
                const SizedBox(height: 16),
                _buildDateField(),
                if (_transactionType != 'card') ...[
                  const SizedBox(height: 16),
                  _buildPaymentStatusField(),
                ],
                if (_transactionType == 'income' ||
                    _transactionType == 'expense') ...[
                  const SizedBox(height: 16),
                  _buildRecurringSection(),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveTransaction,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Salvando...' : 'Salvar transação'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountField(AsyncValue<List<Account>> accountsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Conta'),
        const SizedBox(height: 8),
        accountsAsync.when(
          loading: () {
            return const _LoadingBox(text: 'Carregando contas...');
          },
          error: (error, stackTrace) {
            return const _ErrorBox(
              text: 'Não foi possível carregar as contas.',
            );
          },
          data: (accounts) {
            if (accounts.isEmpty) {
              return const _ErrorBox(text: 'Nenhuma conta ativa cadastrada.');
            }

            final selectedValue =
                accounts.any((account) => account.id == _selectedAccountId)
                ? _selectedAccountId
                : null;

            return DropdownButtonFormField<int>(
              initialValue: selectedValue,
              isExpanded: true,
              decoration: _inputDecoration(
                hintText: 'Selecione uma conta',
                icon: Icons.account_balance_wallet_outlined,
              ),
              items: accounts.map((account) {
                return DropdownMenuItem<int>(
                  value: account.id,
                  child: Text(account.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAccountId = value;

                  if (_selectedDestinationAccountId == value) {
                    _selectedDestinationAccountId = null;
                  }
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Selecione uma conta.';
                }

                return null;
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDestinationAccountField(
    AsyncValue<List<Account>> accountsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Conta de destino'),
        const SizedBox(height: 8),
        accountsAsync.when(
          loading: () {
            return const _LoadingBox(text: 'Carregando contas...');
          },
          error: (error, stackTrace) {
            return const _ErrorBox(
              text: 'Não foi possível carregar as contas.',
            );
          },
          data: (accounts) {
            final availableAccounts = accounts
                .where((account) => account.id != _selectedAccountId)
                .toList();

            if (availableAccounts.isEmpty) {
              return const _ErrorBox(
                text: 'Cadastre pelo menos duas contas para transferir.',
              );
            }

            final selectedValue =
                availableAccounts.any(
                  (account) => account.id == _selectedDestinationAccountId,
                )
                ? _selectedDestinationAccountId
                : null;

            return DropdownButtonFormField<int>(
              initialValue: selectedValue,
              isExpanded: true,
              decoration: _inputDecoration(
                hintText: 'Selecione a conta de destino',
                icon: Icons.move_down_outlined,
              ),
              items: availableAccounts.map((account) {
                return DropdownMenuItem<int>(
                  value: account.id,
                  child: Text(account.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDestinationAccountId = value;
                });
              },
              validator: (value) {
                if (_transactionType == 'transfer' && value == null) {
                  return 'Selecione a conta de destino.';
                }

                if (value == _selectedAccountId) {
                  return 'A conta de destino deve ser diferente.';
                }

                return null;
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryField(AsyncValue<List<Category>> categoriesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Categoria'),
        const SizedBox(height: 8),
        categoriesAsync.when(
          loading: () {
            return const _LoadingBox(text: 'Carregando categorias...');
          },
          error: (error, stackTrace) {
            return const _ErrorBox(
              text: 'Não foi possível carregar as categorias.',
            );
          },
          data: (categories) {
            final activeCategories = categories
                .where((category) => category.isActive)
                .toList();

            if (activeCategories.isEmpty) {
              return const _ErrorBox(text: 'Nenhuma categoria disponível.');
            }

            final selectedValue =
                activeCategories.any(
                  (category) => category.id == _selectedCategoryId,
                )
                ? _selectedCategoryId
                : null;

            return DropdownButtonFormField<int>(
              initialValue: selectedValue,
              isExpanded: true,
              decoration: _inputDecoration(
                hintText: 'Selecione uma categoria',
                icon: Icons.category_outlined,
              ),
              items: activeCategories.map((category) {
                return DropdownMenuItem<int>(
                  value: category.id,
                  child: Text(category.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Selecione uma categoria.';
                }

                return null;
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCreditCardField(AsyncValue<List<CreditCard>> creditCardsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Cartão de crédito'),
        const SizedBox(height: 8),
        creditCardsAsync.when(
          loading: () {
            return const _LoadingBox(text: 'Carregando cartões...');
          },
          error: (error, stackTrace) {
            return const _ErrorBox(
              text: 'Não foi possível carregar os cartões.',
            );
          },
          data: (cards) {
            if (cards.isEmpty) {
              return const _ErrorBox(text: 'Nenhum cartão ativo cadastrado.');
            }

            final selectedValue =
                cards.any((card) => card.id == _selectedCreditCardId)
                ? _selectedCreditCardId
                : null;

            return DropdownButtonFormField<int?>(
              initialValue: selectedValue,
              isExpanded: true,
              decoration: _inputDecoration(
                hintText: 'Sem cartão',
                icon: Icons.credit_card_outlined,
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Sem cartão'),
                ),
                ...cards.map((card) {
                  return DropdownMenuItem<int?>(
                    value: card.id,
                    child: Text(card.name, overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCreditCardId = value;
                });
              },
              validator: (value) {
                if (_transactionType == 'card' && value == null) {
                  return 'Selecione um cartão.';
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildInstallmentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Forma de pagamento'),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: false,
              label: Text('À vista'),
              icon: Icon(Icons.looks_one_outlined),
            ),
            ButtonSegment<bool>(
              value: true,
              label: Text('Parcelada'),
              icon: Icon(Icons.view_week_outlined),
            ),
          ],
          selected: {_isInstallmentPurchase},
          showSelectedIcon: false,
          onSelectionChanged: (selection) {
            setState(() => _isInstallmentPurchase = selection.first);
          },
        ),
        if (_isInstallmentPurchase) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _installments,
            isExpanded: true,
            decoration: _inputDecoration(
              hintText: 'Quantidade de parcelas',
              icon: Icons.calendar_view_month_outlined,
            ),
            items: List.generate(47, (index) {
              final value = index + 2;
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value parcelas'),
              );
            }),
            onChanged: (value) {
              if (value != null) setState(() => _installments = value);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Data'),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _selectDate,
          child: InputDecorator(
            decoration: _inputDecoration(
              hintText: 'Selecione uma data',
              icon: Icons.calendar_month_outlined,
            ),
            child: Text(_formatDate(_occurredAt)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusField() {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      value: _isPaid,
      title: Text(switch (_transactionType) {
        'income' => 'Receita recebida',
        'expense' => 'Despesa paga',
        'transfer' => 'Transferência realizada',
        _ => 'Transação concluída',
      }),
      subtitle: Text(
        _isPaid
            ? 'O valor será considerado no saldo.'
            : 'O lançamento ficará pendente.',
      ),
      onChanged: (value) {
        setState(() {
          _isPaid = value;
        });
      },
    );
  }

  Widget _buildRecurringSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _isRecurring,
            title: const Text('Tornar recorrente'),
            subtitle: const Text(
              'Cria uma regra para repetir este lançamento.',
            ),
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _isRecurring = value;
                      if (!value) {
                        _recurrenceEndDate = null;
                      }
                    });
                  },
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 12),
            const _FieldLabel('Frequência'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _recurrenceFrequency,
              isExpanded: true,
              decoration: _inputDecoration(
                hintText: 'Selecione a frequência',
                icon: Icons.repeat_rounded,
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Diária')),
                DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                DropdownMenuItem(value: 'biweekly', child: Text('Quinzenal')),
                DropdownMenuItem(value: 'monthly', child: Text('Mensal')),
                DropdownMenuItem(value: 'bimonthly', child: Text('Bimestral')),
                DropdownMenuItem(value: 'quarterly', child: Text('Trimestral')),
                DropdownMenuItem(value: 'semiannual', child: Text('Semestral')),
                DropdownMenuItem(value: 'yearly', child: Text('Anual')),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _recurrenceFrequency = value);
                      }
                    },
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Data final (opcional)'),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _isSaving ? null : _selectRecurrenceEndDate,
              child: InputDecorator(
                decoration:
                    _inputDecoration(
                      hintText: 'Sem data final',
                      icon: Icons.event_busy_outlined,
                    ).copyWith(
                      suffixIcon: _recurrenceEndDate == null
                          ? null
                          : IconButton(
                              tooltip: 'Remover data final',
                              onPressed: _isSaving
                                  ? null
                                  : () {
                                      setState(() => _recurrenceEndDate = null);
                                    },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                child: Text(
                  _recurrenceEndDate == null
                      ? 'Sem data final'
                      : _formatDate(_recurrenceEndDate!),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _autoGenerateRecurrence,
              title: const Text('Gerar automaticamente'),
              subtitle: const Text(
                'O lançamento será criado quando chegar a próxima data.',
              ),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() => _autoGenerateRecurrence = value);
                    },
            ),
            const SizedBox(height: 8),
            _buildRecurrencePreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildRecurrencePreview() {
    final dates = <DateTime>[];
    var next = _nextOccurrence(_occurredAt, _recurrenceFrequency);

    for (var index = 0; index < 4; index++) {
      if (_recurrenceEndDate != null && next.isAfter(_recurrenceEndDate!)) {
        break;
      }
      dates.add(next);
      next = _nextOccurrence(next, _recurrenceFrequency);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Próximas ocorrências',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (dates.isEmpty)
            const Text('Nenhuma ocorrência dentro do período selecionado.')
          else
            ...dates.map(
              (date) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(_formatDate(date)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectRecurrenceEndDate() async {
    final firstAllowed = _nextOccurrence(_occurredAt, _recurrenceFrequency);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? firstAllowed,
      firstDate: firstAllowed,
      lastDate: DateTime(2100),
      helpText: 'Selecione a data final',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() => _recurrenceEndDate = selectedDate);
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Selecione a data',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _occurredAt = selectedDate;
      final minimumEnd = _nextOccurrence(_occurredAt, _recurrenceFrequency);
      if (_recurrenceEndDate != null &&
          _recurrenceEndDate!.isBefore(minimumEnd)) {
        _recurrenceEndDate = null;
      }
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String get _descriptionHint {
    switch (_transactionType) {
      case 'income':
        return 'Ex.: Salário';
      case 'transfer':
        return 'Ex.: Transferência para poupança';
      case 'card':
        return 'Ex.: Notebook';
      case 'expense':
      default:
        return 'Ex.: Supermercado';
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Future<void> _saveTransaction() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isSaving) {
      return;
    }

    final accountId = _selectedAccountId;

    if (_transactionType != 'card' && accountId == null) {
      _showMessage('Selecione uma conta.', isError: true);
      return;
    }

    if (_transactionType == 'card' && _selectedCreditCardId == null) {
      _showMessage('Selecione um cartão.', isError: true);
      return;
    }

    if (_transactionType == 'transfer' &&
        _selectedDestinationAccountId == null) {
      _showMessage('Selecione a conta de destino.', isError: true);
      return;
    }

    final amountCents = _parseAmountToCents(_amountController.text);

    if (amountCents == null || amountCents <= 0) {
      _showMessage('Informe um valor válido.', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(ledgerEntriesRepositoryProvider);

      if (_transactionType == 'card') {
        final cardRepository = ref.read(creditCardsRepositoryProvider);
        final card = await cardRepository.getCreditCardById(
          _selectedCreditCardId!,
        );
        if (card == null) throw StateError('Cartão não encontrado.');

        final installments = _isInstallmentPurchase ? _installments : 1;
        final baseCents = amountCents ~/ installments;
        final remainder = amountCents % installments;
        final firstDueDate = _calculateFirstDueDate(
          purchaseDate: _occurredAt,
          closingDay: card.closingDay,
          dueDay: card.dueDay,
        );

        for (var index = 0; index < installments; index++) {
          final number = index + 1;
          final installmentCents = baseCents + (index < remainder ? 1 : 0);
          await repository.createEntry(
            description: installments == 1
                ? _descriptionController.text.trim()
                : '${_descriptionController.text.trim()} ($number/$installments)',
            amountCents: installmentCents,
            type: 'expense',
            accountId: card.accountId,
            categoryId: _selectedCategoryId,
            creditCardId: card.id,
            occurredAt: _occurredAt,
            dueDate: _addMonthsKeepingDay(firstDueDate, index, card.dueDay),
            isPaid: false,
            notes: installments > 1 ? 'Parcela $number de $installments' : null,
          );
        }
      } else {
        await repository.createEntry(
          description: _descriptionController.text.trim(),
          amountCents: amountCents,
          type: _transactionType,
          accountId: accountId!,
          destinationAccountId: _transactionType == 'transfer'
              ? _selectedDestinationAccountId
              : null,
          categoryId: _transactionType == 'transfer'
              ? null
              : _selectedCategoryId,
          occurredAt: _occurredAt,
          isPaid: _isPaid,
        );

        if (_isRecurring &&
            (_transactionType == 'income' || _transactionType == 'expense')) {
          final nextOccurrence = _nextOccurrence(
            _occurredAt,
            _recurrenceFrequency,
          );

          if (_recurrenceEndDate != null &&
              nextOccurrence.isAfter(_recurrenceEndDate!)) {
            throw StateError(
              'A data final deve permitir ao menos uma repetição.',
            );
          }

          final recurringRepository = ref.read(
            recurringTransactionsRepositoryProvider,
          );
          await recurringRepository.createRecurringTransaction(
            description: _descriptionController.text.trim(),
            amountCents: amountCents,
            type: _transactionType,
            accountId: accountId,
            categoryId: _selectedCategoryId,
            frequency: _recurrenceFrequency,
            startDate: _occurredAt,
            nextOccurrence: nextOccurrence,
            endDate: _recurrenceEndDate,
            autoGenerate: _autoGenerateRecurrence,
          );
        }
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transação salva com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Não foi possível salvar a transação: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  DateTime _nextOccurrence(DateTime date, String frequency) {
    final source = DateUtils.dateOnly(date);

    switch (frequency) {
      case 'daily':
        return source.add(const Duration(days: 1));
      case 'weekly':
        return source.add(const Duration(days: 7));
      case 'biweekly':
        return source.add(const Duration(days: 14));
      case 'bimonthly':
        return _addMonthsForRecurrence(source, 2);
      case 'quarterly':
        return _addMonthsForRecurrence(source, 3);
      case 'semiannual':
        return _addMonthsForRecurrence(source, 6);
      case 'yearly':
        return _addMonthsForRecurrence(source, 12);
      case 'monthly':
      default:
        return _addMonthsForRecurrence(source, 1);
    }
  }

  DateTime _addMonthsForRecurrence(DateTime date, int months) {
    final target = DateTime(date.year, date.month + months);
    final day = _safeDay(target.year, target.month, date.day);
    return DateTime(target.year, target.month, day);
  }

  DateTime _calculateFirstDueDate({
    required DateTime purchaseDate,
    required int closingDay,
    required int dueDay,
  }) {
    final effectiveClosingDay = _safeDay(
      purchaseDate.year,
      purchaseDate.month,
      closingDay,
    );
    final invoiceMonthOffset = purchaseDate.day >= effectiveClosingDay ? 2 : 1;
    final target = DateTime(
      purchaseDate.year,
      purchaseDate.month + invoiceMonthOffset,
    );
    return DateTime(
      target.year,
      target.month,
      _safeDay(target.year, target.month, dueDay),
    );
  }

  DateTime _addMonthsKeepingDay(DateTime date, int months, int day) {
    final target = DateTime(date.year, date.month + months);
    return DateTime(
      target.year,
      target.month,
      _safeDay(target.year, target.month, day),
    );
  }

  int _safeDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return day.clamp(1, lastDay).toInt();
  }

  int? _parseAmountToCents(String value) {
    final normalized = value
        .trim()
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');

    final amount = double.tryParse(normalized);

    if (amount == null) {
      return null;
    }

    return (amount * 100).round();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.error),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
