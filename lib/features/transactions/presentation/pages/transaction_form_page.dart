import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/categories_providers.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/ledger_entries_providers.dart';
import '../../../../core/utils/category_visuals.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key, this.entry});

  final LedgerEntry? entry;

  bool get isEditing => entry != null;

  @override
  ConsumerState<TransactionFormPage> createState() {
    return _TransactionFormPageState();
  }
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  late String _selectedType;
  int? _selectedAccountId;
  int? _selectedDestinationAccountId;
  int? _selectedCategoryId;

  late DateTime _occurredAt;
  DateTime? _dueDate;

  late bool _isPaid;
  bool _isSaving = false;

  bool get _isTransfer => _selectedType == 'transfer';

  bool get _isIncome => _selectedType == 'income';

  @override
  void initState() {
    super.initState();

    final entry = widget.entry;

    _descriptionController = TextEditingController(
      text: entry?.description ?? '',
    );

    _amountController = TextEditingController(
      text: entry == null
          ? ''
          : _CurrencyInputFormatter.formatCents(entry.amountCents),
    );

    _notesController = TextEditingController(text: entry?.notes ?? '');

    _selectedType = entry?.type ?? 'expense';
    _selectedAccountId = entry?.accountId;
    _selectedDestinationAccountId = entry?.destinationAccountId;
    _selectedCategoryId = entry?.categoryId;

    _occurredAt = entry?.occurredAt ?? DateTime.now();
    _dueDate = entry?.dueDate;
    _isPaid = entry?.isPaid ?? true;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsStreamProvider);

    final categoriesAsync = _isIncome
        ? ref.watch(incomeCategoriesStreamProvider)
        : ref.watch(expenseCategoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar transação' : 'Nova transação'),
      ),
      body: accountsAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return _LoadError(
            message: 'Erro ao carregar contas: $error',
            onRetry: () {
              ref.invalidate(accountsStreamProvider);
            },
          );
        },
        data: (accounts) {
          final activeAccounts = accounts
              .where(
                (account) =>
                    account.isActive ||
                    account.id == _selectedAccountId ||
                    account.id == _selectedDestinationAccountId,
              )
              .toList();

          return categoriesAsync.when(
            loading: () {
              return const Center(child: CircularProgressIndicator());
            },
            error: (error, stackTrace) {
              return _LoadError(
                message: 'Erro ao carregar categorias: $error',
                onRetry: () {
                  ref.invalidate(incomeCategoriesStreamProvider);

                  ref.invalidate(expenseCategoriesStreamProvider);
                },
              );
            },
            data: (categories) {
              final activeCategories = categories
                  .where(
                    (category) =>
                        category.isActive || category.id == _selectedCategoryId,
                  )
                  .toList();

              return _buildForm(
                accounts: activeAccounts,
                categories: activeCategories,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildForm({
    required List<Account> accounts,
    required List<Category> categories,
  }) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _SectionCard(
            title: 'Tipo da transação',
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'expense',
                  icon: Icon(Icons.arrow_upward),
                  label: Text('Despesa'),
                ),
                ButtonSegment(
                  value: 'income',
                  icon: Icon(Icons.arrow_downward),
                  label: Text('Receita'),
                ),
                ButtonSegment(
                  value: 'transfer',
                  icon: Icon(Icons.swap_horiz),
                  label: Text('Transferir'),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: _isSaving
                  ? null
                  : (selection) {
                      _changeTransactionType(selection.first);
                    },
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Informações',
            child: Column(
              children: [
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Ex.: Supermercado',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe uma descrição.';
                    }

                    if (value.trim().length > 150) {
                      return 'Use no máximo 150 caracteres.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_CurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    hintText: 'R\$ 0,00',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    final amountCents = _parseAmountCents(value ?? '');

                    if (amountCents <= 0) {
                      return 'Informe um valor maior que zero.';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: _isTransfer
                ? 'Contas da transferência'
                : 'Conta e categoria',
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  key: ValueKey('account-$_selectedAccountId'),
                  initialValue: _validSelectedId(
                    items: accounts,
                    selectedId: _selectedAccountId,
                    getId: (account) => account.id,
                  ),
                  decoration: InputDecoration(
                    labelText: _isTransfer ? 'Conta de origem' : 'Conta',
                    prefixIcon: const Icon(Icons.account_balance),
                  ),
                  items: accounts.map((account) {
                    return DropdownMenuItem<int>(
                      value: account.id,
                      child: Text(account.name),
                    );
                  }).toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
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
                ),
                if (_isTransfer) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    key: ValueKey(
                      'destination-'
                      '$_selectedDestinationAccountId-'
                      '$_selectedAccountId',
                    ),
                    initialValue: _validSelectedId(
                      items: accounts,
                      selectedId: _selectedDestinationAccountId,
                      getId: (account) => account.id,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Conta de destino',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    items: accounts
                        .where((account) => account.id != _selectedAccountId)
                        .map((account) {
                          return DropdownMenuItem<int>(
                            value: account.id,
                            child: Text(account.name),
                          );
                        })
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _selectedDestinationAccountId = value;
                            });
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione a conta de destino.';
                      }

                      if (value == _selectedAccountId) {
                        return 'A conta de destino deve ser diferente.';
                      }

                      return null;
                    },
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    key: ValueKey(
                      'category-$_selectedType-'
                      '$_selectedCategoryId',
                    ),
                    initialValue: _validSelectedId(
                      items: categories,
                      selectedId: _selectedCategoryId,
                      getId: (category) => category.id,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: categories.map((category) {
                      final fallbackColor = category.type == 'income'
                          ? Colors.green
                          : Colors.red;

                      final color = CategoryVisuals.colorFromHex(
                        category.colorHex,
                        fallback: fallbackColor,
                      );

                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Row(
                          children: [
                            Icon(
                              CategoryVisuals.iconFromName(category.iconName),
                              color: color,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              category.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Datas e situação',
            child: Column(
              children: [
                _DateField(
                  label: 'Data da transação',
                  date: _occurredAt,
                  icon: Icons.event,
                  enabled: !_isSaving,
                  onTap: () async {
                    final selectedDate = await _selectDate(
                      initialDate: _occurredAt,
                    );

                    if (selectedDate == null) {
                      return;
                    }

                    setState(() {
                      _occurredAt = selectedDate;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _DateField(
                  label: 'Data de vencimento',
                  date: _dueDate,
                  icon: Icons.event_available,
                  enabled: !_isSaving,
                  allowClear: true,
                  onClear: () {
                    setState(() {
                      _dueDate = null;
                    });
                  },
                  onTap: () async {
                    final selectedDate = await _selectDate(
                      initialDate: _dueDate ?? _occurredAt,
                    );

                    if (selectedDate == null) {
                      return;
                    }

                    setState(() {
                      _dueDate = selectedDate;
                    });
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isPaid,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _isPaid = value;
                          });
                        },
                  title: Text(_isPaid ? 'Pago' : 'Pendente'),
                  subtitle: Text(
                    _isPaid
                        ? 'O valor já foi movimentado.'
                        : 'O lançamento ainda está em aberto.',
                  ),
                  secondary: Icon(
                    _isPaid ? Icons.check_circle_outline : Icons.schedule,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Observações',
            child: TextFormField(
              controller: _notesController,
              enabled: !_isSaving,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Adicione informações opcionais...',
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isSaving || accounts.isEmpty ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              _isSaving
                  ? 'Salvando...'
                  : widget.isEditing
                  ? 'Atualizar transação'
                  : 'Salvar transação',
            ),
          ),
          if (accounts.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Cadastre uma conta antes de criar uma transação.',
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  void _changeTransactionType(String type) {
    if (type == _selectedType) {
      return;
    }

    setState(() {
      _selectedType = type;
      _selectedCategoryId = null;

      if (type != 'transfer') {
        _selectedDestinationAccountId = null;
      }
    });
  }

  Future<DateTime?> _selectDate({required DateTime initialDate}) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isTransfer && _selectedDestinationAccountId == _selectedAccountId) {
      _showMessage('Selecione contas diferentes para a transferência.');
      return;
    }

    final amountCents = _parseAmountCents(_amountController.text);

    setState(() {
      _isSaving = true;
    });

    final repository = ref.read(ledgerEntriesRepositoryProvider);

    try {
      if (widget.isEditing) {
        await repository.updateEntry(
          id: widget.entry!.id,
          description: _descriptionController.text.trim(),
          amountCents: amountCents,
          type: _selectedType,
          accountId: _selectedAccountId,
          destinationAccountId: _isTransfer
              ? _selectedDestinationAccountId
              : null,
          categoryId: _isTransfer ? null : _selectedCategoryId,
          occurredAt: _occurredAt,
          dueDate: _dueDate,
          isPaid: _isPaid,
          notes: _nullableText(_notesController.text),
        );
      } else {
        await repository.createEntry(
          description: _descriptionController.text.trim(),
          amountCents: amountCents,
          type: _selectedType,
          accountId: _selectedAccountId!,
          destinationAccountId: _isTransfer
              ? _selectedDestinationAccountId
              : null,
          categoryId: _isTransfer ? null : _selectedCategoryId,
          occurredAt: _occurredAt,
          dueDate: _dueDate,
          isPaid: _isPaid,
          notes: _nullableText(_notesController.text),
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage('Não foi possível salvar a transação: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  int _parseAmountCents(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    return int.tryParse(digits) ?? 0;
  }

  String? _nullableText(String value) {
    final text = value.trim();

    return text.isEmpty ? null : text;
  }

  int? _validSelectedId<T>({
    required List<T> items,
    required int? selectedId,
    required int Function(T item) getId,
  }) {
    if (selectedId == null) {
      return null;
    }

    final exists = items.any((item) => getId(item) == selectedId);

    return exists ? selectedId : null;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.icon,
    required this.onTap,
    required this.enabled,
    this.allowClear = false,
    this.onClear,
  });

  final String label;
  final DateTime? date;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool allowClear;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final formattedDate = date == null ? 'Não informado' : _formatDate(date!);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: allowClear && date != null
              ? IconButton(
                  tooltip: 'Remover data',
                  onPressed: enabled ? onClear : null,
                  icon: const Icon(Icons.close),
                )
              : const Icon(Icons.calendar_month),
        ),
        child: Text(formattedDate),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
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

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    final cents = int.tryParse(digits) ?? 0;
    final formatted = formatCents(cents);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String formatCents(int cents) {
    final reais = cents ~/ 100;
    final centavos = (cents % 100).toString().padLeft(2, '0');

    final reaisText = reais.toString();
    final buffer = StringBuffer();

    for (var index = 0; index < reaisText.length; index++) {
      final remaining = reaisText.length - index;

      buffer.write(reaisText[index]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'R\$ ${buffer.toString()},$centavos';
  }
}
