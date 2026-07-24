import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/accounts_providers.dart';
import '../../../../core/providers/categories_providers.dart';
import '../../../../core/providers/recurring_transactions_providers.dart';

Future<void> showRecurringTransactionFormDialog({
  required BuildContext context,
  required WidgetRef ref,
  RecurringTransaction? recurringTransaction,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _RecurringTransactionFormDialog(
      recurringTransaction: recurringTransaction,
    ),
  );
}

class _RecurringTransactionFormDialog extends ConsumerStatefulWidget {
  const _RecurringTransactionFormDialog({this.recurringTransaction});

  final RecurringTransaction? recurringTransaction;

  @override
  ConsumerState<_RecurringTransactionFormDialog> createState() =>
      _RecurringTransactionFormDialogState();
}

class _RecurringTransactionFormDialogState
    extends ConsumerState<_RecurringTransactionFormDialog> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  late String _type;
  late String _frequency;
  int? _accountId;
  int? _categoryId;
  late DateTime _startDate;
  DateTime? _endDate;
  late bool _isActive;
  late bool _autoGenerate;
  bool _saving = false;

  bool get _isEditing => widget.recurringTransaction != null;

  @override
  void initState() {
    super.initState();
    final item = widget.recurringTransaction;
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _amountController = TextEditingController(
      text: item == null ? '' : _editableCurrency(item.amountCents),
    );
    _notesController = TextEditingController(text: item?.notes ?? '');
    _type = item?.type ?? 'expense';
    _frequency = item?.frequency ?? 'monthly';
    _accountId = item?.accountId;
    _categoryId = item?.categoryId;
    _startDate = DateUtils.dateOnly(item?.startDate ?? DateTime.now());
    _endDate = item?.endDate == null
        ? null
        : DateUtils.dateOnly(item!.endDate!);
    _isActive = item?.isActive ?? true;
    _autoGenerate = item?.autoGenerate ?? true;
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
    final accountsAsync = ref.watch(activeAccountsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return AlertDialog(
      title: Text(_isEditing ? 'Editar recorrência' : 'Nova recorrência'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
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
                ],
                selected: {_type},
                onSelectionChanged: _saving
                    ? null
                    : (selection) => setState(() {
                        _type = selection.first;
                        _categoryId = null;
                      }),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _descriptionController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Ex.: Aluguel, salário ou streaming',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _amountController,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                ),
              ),
              const SizedBox(height: 14),
              accountsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Erro ao carregar contas: $error'),
                data: (accounts) {
                  if (_accountId == null && accounts.isNotEmpty) {
                    _accountId = accounts.first.id;
                  }
                  return DropdownButtonFormField<int>(
                    initialValue: accounts.any((a) => a.id == _accountId)
                        ? _accountId
                        : null,
                    decoration: const InputDecoration(labelText: 'Conta'),
                    items: accounts
                        .map(
                          (account) => DropdownMenuItem(
                            value: account.id,
                            child: Text(account.name),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _accountId = value),
                  );
                },
              ),
              const SizedBox(height: 14),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) =>
                    Text('Erro ao carregar categorias: $error'),
                data: (categories) {
                  final filtered = categories
                      .where(
                        (category) =>
                            category.type == _type && category.isActive,
                      )
                      .toList();
                  return DropdownButtonFormField<int?>(
                    initialValue: filtered.any((c) => c.id == _categoryId)
                        ? _categoryId
                        : null,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sem categoria'),
                      ),
                      ...filtered.map(
                        (category) => DropdownMenuItem<int?>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _categoryId = value),
                  );
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Frequência'),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Diária')),
                  DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                  DropdownMenuItem(value: 'biweekly', child: Text('Quinzenal')),
                  DropdownMenuItem(value: 'monthly', child: Text('Mensal')),
                  DropdownMenuItem(
                    value: 'bimonthly',
                    child: Text('Bimestral'),
                  ),
                  DropdownMenuItem(
                    value: 'quarterly',
                    child: Text('Trimestral'),
                  ),
                  DropdownMenuItem(
                    value: 'semiannual',
                    child: Text('Semestral'),
                  ),
                  DropdownMenuItem(value: 'yearly', child: Text('Anual')),
                ],
                onChanged: _saving
                    ? null
                    : (value) =>
                          setState(() => _frequency = value ?? 'monthly'),
              ),
              const SizedBox(height: 14),
              _DateField(
                label: 'Primeira ocorrência',
                value: _startDate,
                onTap: _saving ? null : () => _pickStartDate(context),
              ),
              const SizedBox(height: 14),
              _DateField(
                label: 'Última ocorrência (opcional)',
                value: _endDate,
                onTap: _saving ? null : () => _pickEndDate(context),
                onClear: _endDate == null || _saving
                    ? null
                    : () => setState(() => _endDate = null),
              ),
              const SizedBox(height: 10),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Gerar automaticamente'),
                subtitle: const Text('Cria o lançamento quando chegar a data.'),
                value: _autoGenerate,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _autoGenerate = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recorrência ativa'),
                value: _isActive,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                enabled: !_saving,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(
            _saving ? 'Salvando...' : (_isEditing ? 'Atualizar' : 'Salvar'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    setState(() {
      _startDate = DateUtils.dateOnly(selected);
      if (_endDate != null && _endDate!.isBefore(_startDate)) _endDate = null;
    });
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (selected != null)
      setState(() => _endDate = DateUtils.dateOnly(selected));
  }

  Future<void> _save() async {
    final description = _descriptionController.text.trim();
    final amountCents = _parseCurrency(_amountController.text);
    if (description.isEmpty) return _message('Informe a descrição.');
    if (amountCents <= 0) return _message('Informe um valor maior que zero.');
    if (_accountId == null) return _message('Selecione uma conta.');
    if (_endDate != null && _endDate!.isBefore(_startDate)) {
      return _message('A data final não pode ser anterior à inicial.');
    }

    setState(() => _saving = true);
    try {
      final repository = ref.read(recurringTransactionsRepositoryProvider);
      final notes = _notesController.text.trim();
      if (_isEditing) {
        await repository.updateRecurringTransaction(
          id: widget.recurringTransaction!.id,
          description: description,
          amountCents: amountCents,
          type: _type,
          accountId: _accountId,
          categoryId: Value(_categoryId),
          frequency: _frequency,
          startDate: _startDate,
          endDate: Value(_endDate),
          nextOccurrence: _startDate,
          isActive: _isActive,
          autoGenerate: _autoGenerate,
          notes: Value(notes.isEmpty ? null : notes),
        );
      } else {
        await repository.createRecurringTransaction(
          description: description,
          amountCents: amountCents,
          type: _type,
          accountId: _accountId!,
          categoryId: _categoryId,
          frequency: _frequency,
          startDate: _startDate,
          nextOccurrence: _startDate,
          endDate: _endDate,
          isActive: _isActive,
          autoGenerate: _autoGenerate,
          notes: notes.isEmpty ? null : notes,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _message('Não foi possível salvar: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  int _parseCurrency(String value) {
    var normalized = value.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }
    return ((double.tryParse(normalized) ?? 0) * 100).round();
  }

  String _editableCurrency(int cents) {
    return NumberFormat('0.00', 'pt_BR').format(cents / 100);
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: onClear == null
              ? const Icon(Icons.calendar_month_outlined)
              : IconButton(onPressed: onClear, icon: const Icon(Icons.clear)),
        ),
        child: Text(
          value == null
              ? 'Sem data final'
              : DateFormat('dd/MM/yyyy').format(value!),
        ),
      ),
    );
  }
}
