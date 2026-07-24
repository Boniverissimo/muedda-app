import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/categories_providers.dart';
import '../../../../core/providers/ledger_entries_providers.dart';

class CreditCardPurchaseFormDialog extends ConsumerStatefulWidget {
  const CreditCardPurchaseFormDialog({super.key, required this.creditCard});

  final CreditCard creditCard;

  @override
  ConsumerState<CreditCardPurchaseFormDialog> createState() =>
      _CreditCardPurchaseFormDialogState();
}

enum _PurchaseMode { cash, installments }

class _CreditCardPurchaseFormDialogState
    extends ConsumerState<CreditCardPurchaseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _purchaseDate = DateTime.now();
  int? _categoryId;
  int _installments = 1;
  _PurchaseMode _purchaseMode = _PurchaseMode.cash;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _amountController.removeListener(_refreshPreview);
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesStreamProvider);
    final totalCents = _parseCurrencyToCents(_amountController.text);
    final effectiveInstallments = _purchaseMode == _PurchaseMode.cash
        ? 1
        : _installments;
    final firstDueDate = _calculateFirstDueDate(
      purchaseDate: _purchaseDate,
      closingDay: widget.creditCard.closingDay,
      dueDay: widget.creditCard.dueDay,
    );

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.add_shopping_cart_outlined),
          const SizedBox(width: 10),
          const Expanded(child: Text('Lançar compra no cartão')),
          IconButton(
            tooltip: 'Fechar',
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: categoriesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) =>
              Text('Não foi possível carregar as categorias: $error'),
          data: (categories) {
            final activeCategories = categories
                .where((category) => category.isActive)
                .toList(growable: false);

            if (_categoryId != null &&
                !activeCategories.any((item) => item.id == _categoryId)) {
              _categoryId = null;
            }

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CardIdentification(creditCard: widget.creditCard),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Descrição da compra',
                        hintText: 'Ex.: Notebook, supermercado, combustível',
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe a descrição da compra.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Valor total da compra',
                        hintText: '0,00',
                        prefixText: 'R\$ ',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      validator: (value) {
                        if (_parseCurrencyToCents(value ?? '') <= 0) {
                          return 'Informe um valor maior que zero.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: activeCategories
                          .map(
                            (category) => DropdownMenuItem<int>(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _categoryId = value),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Forma de pagamento',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<_PurchaseMode>(
                      segments: const [
                        ButtonSegment<_PurchaseMode>(
                          value: _PurchaseMode.cash,
                          icon: Icon(Icons.looks_one_outlined),
                          label: Text('À vista'),
                        ),
                        ButtonSegment<_PurchaseMode>(
                          value: _PurchaseMode.installments,
                          icon: Icon(Icons.view_week_outlined),
                          label: Text('Parcelada'),
                        ),
                      ],
                      selected: {_purchaseMode},
                      onSelectionChanged: _saving
                          ? null
                          : (selection) {
                              setState(() {
                                _purchaseMode = selection.first;
                                if (_purchaseMode == _PurchaseMode.cash) {
                                  _installments = 1;
                                } else if (_installments == 1) {
                                  _installments = 2;
                                }
                              });
                            },
                    ),
                    if (_purchaseMode == _PurchaseMode.installments) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: _installments,
                        decoration: const InputDecoration(
                          labelText: 'Quantidade de parcelas',
                          prefixIcon: Icon(Icons.calendar_view_month_outlined),
                        ),
                        items: List.generate(47, (index) {
                          final value = index + 2;
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(
                              '$value parcelas de ${_formatMoney(_installmentValue(totalCents, value, 0))}',
                            ),
                          );
                        }),
                        onChanged: _saving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _installments = value);
                                }
                              },
                      ),
                    ],
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _saving ? null : _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data da compra',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_purchaseDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Observações (opcional)',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PurchasePreview(
                      totalCents: totalCents,
                      installments: effectiveInstallments,
                      firstDueDate: firstDueDate,
                      dueDay: widget.creditCard.dueDay,
                      closingDay: widget.creditCard.closingDay,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_saving ? 'Salvando...' : 'Lançar compra'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 10),
    );

    if (selected != null) {
      setState(() => _purchaseDate = selected);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final repository = ref.read(ledgerEntriesRepositoryProvider);
      final totalCents = _parseCurrencyToCents(_amountController.text);
      final installments = _purchaseMode == _PurchaseMode.cash
          ? 1
          : _installments;
      final baseCents = totalCents ~/ installments;
      final remainder = totalCents % installments;
      final firstDueDate = _calculateFirstDueDate(
        purchaseDate: _purchaseDate,
        closingDay: widget.creditCard.closingDay,
        dueDay: widget.creditCard.dueDay,
      );
      final purchaseDescription = _descriptionController.text.trim();

      for (var index = 0; index < installments; index++) {
        final installmentNumber = index + 1;
        final installmentCents = baseCents + (index < remainder ? 1 : 0);
        final dueDate = _addMonthsKeepingDay(
          firstDueDate,
          index,
          widget.creditCard.dueDay,
        );
        final description = installments == 1
            ? purchaseDescription
            : '$purchaseDescription ($installmentNumber/$installments)';
        final notesParts = <String>[
          if (_notesController.text.trim().isNotEmpty)
            _notesController.text.trim(),
          'Compra realizada em ${DateFormat('dd/MM/yyyy').format(_purchaseDate)}',
          if (installments > 1) 'Parcela $installmentNumber de $installments',
          if (installments > 1) 'Valor total: ${_formatMoney(totalCents)}',
        ];

        await repository.createEntry(
          description: description,
          amountCents: installmentCents,
          type: 'expense',
          accountId: widget.creditCard.accountId,
          categoryId: _categoryId,
          creditCardId: widget.creditCard.id,
          occurredAt: _purchaseDate,
          dueDate: dueDate,
          isPaid: false,
          notes: notesParts.join('\n'),
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar a compra: $error')),
        );
        setState(() => _saving = false);
      }
    }
  }

  DateTime _calculateFirstDueDate({
    required DateTime purchaseDate,
    required int closingDay,
    required int dueDay,
  }) {
    final normalizedPurchase = DateTime(
      purchaseDate.year,
      purchaseDate.month,
      purchaseDate.day,
    );
    final closingDate = DateTime(
      purchaseDate.year,
      purchaseDate.month,
      _validDay(purchaseDate.year, purchaseDate.month, closingDay),
    );
    final invoiceOffset = normalizedPurchase.isAfter(closingDate) ? 2 : 1;
    final targetMonth = DateTime(
      purchaseDate.year,
      purchaseDate.month + invoiceOffset,
    );

    return DateTime(
      targetMonth.year,
      targetMonth.month,
      _validDay(targetMonth.year, targetMonth.month, dueDay),
    );
  }

  DateTime _addMonthsKeepingDay(DateTime source, int months, int desiredDay) {
    final target = DateTime(source.year, source.month + months);
    return DateTime(
      target.year,
      target.month,
      _validDay(target.year, target.month, desiredDay),
    );
  }

  int _validDay(int year, int month, int desiredDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    if (desiredDay < 1) return 1;
    if (desiredDay > lastDay) return lastDay;
    return desiredDay;
  }

  int _parseCurrencyToCents(String input) {
    var normalized = input.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (normalized.isEmpty) return 0;

    if (normalized.contains(',') && normalized.contains('.')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else if (normalized.contains(',')) {
      normalized = normalized.replaceAll(',', '.');
    }

    final value = double.tryParse(normalized);
    return value == null ? 0 : (value * 100).round();
  }
}

class _CardIdentification extends StatelessWidget {
  const _CardIdentification({required this.creditCard});

  final CreditCard creditCard;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.credit_card)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    creditCard.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Fecha dia ${creditCard.closingDay} • Vence dia ${creditCard.dueDay}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              'Limite ${_formatMoney(creditCard.limitCents)}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchasePreview extends StatelessWidget {
  const _PurchasePreview({
    required this.totalCents,
    required this.installments,
    required this.firstDueDate,
    required this.dueDay,
    required this.closingDay,
  });

  final int totalCents;
  final int installments;
  final DateTime firstDueDate;
  final int dueDay;
  final int closingDay;

  @override
  Widget build(BuildContext context) {
    final firstInstallment = _installmentValue(totalCents, installments, 0);
    final lastDueDate = DateTime(
      firstDueDate.year,
      firstDueDate.month + installments - 1,
      firstDueDate.day,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined),
                const SizedBox(width: 8),
                Text(
                  'Prévia do lançamento',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PreviewLine(
              label: installments == 1 ? 'Lançamento' : 'Parcelamento',
              value: installments == 1
                  ? 'À vista'
                  : '${installments}x de aproximadamente ${_formatMoney(firstInstallment)}',
            ),
            _PreviewLine(
              label: 'Primeira fatura',
              value: DateFormat("MMMM 'de' yyyy", 'pt_BR').format(firstDueDate),
            ),
            if (installments > 1)
              _PreviewLine(
                label: 'Última parcela',
                value: DateFormat(
                  "MMMM 'de' yyyy",
                  'pt_BR',
                ).format(lastDueDate),
              ),
            _PreviewLine(
              label: 'Impacto no limite',
              value: _formatMoney(totalCents),
            ),
            const SizedBox(height: 8),
            Text(
              'O app criará ${installments == 1 ? '1 lançamento' : '$installments parcelas'} automaticamente. '
              'Compras feitas após o fechamento (dia $closingDay) entram na fatura seguinte. '
              'O vencimento será sempre no dia $dueDay.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

int _installmentValue(int totalCents, int installments, int index) {
  if (totalCents <= 0 || installments <= 0) return 0;
  final base = totalCents ~/ installments;
  final remainder = totalCents % installments;
  return base + (index < remainder ? 1 : 0);
}

String _formatMoney(int cents) {
  return NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  ).format(cents / 100);
}
