import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../database/app_database.dart';

class ReportExportService {
  ReportExportService();

  Future<File> exportCsv({
    required DateTime start,
    required DateTime end,
    required List<LedgerEntry> entries,
    required List<Account> accounts,
    required List<Category> categories,
  }) async {
    final accountNames = {
      for (final account in accounts) account.id: account.name,
    };
    final categoryNames = {
      for (final category in categories) category.id: category.name,
    };

    final rows = <List<String>>[
      [
        'Data',
        'Descrição',
        'Tipo',
        'Valor',
        'Conta',
        'Categoria',
        'Vencimento',
        'Status',
        'Observações',
      ],
      ...entries.map(
        (entry) => [
          _formatDate(entry.occurredAt),
          entry.description,
          _typeLabel(entry.type),
          (entry.amountCents / 100).toStringAsFixed(2).replaceAll('.', ','),
          accountNames[entry.accountId] ?? 'Conta #${entry.accountId}',
          entry.categoryId == null
              ? ''
              : categoryNames[entry.categoryId] ??
                    'Categoria #${entry.categoryId}',
          entry.dueDate == null ? '' : _formatDate(entry.dueDate!),
          entry.isPaid ? _completedStatus(entry.type) : 'Pendente',
          entry.notes ?? '',
        ],
      ),
    ];

    final content = rows.map(_csvRow).join('\r\n');
    final file = await _createOutputFile(
      extension: 'csv',
      start: start,
      end: end,
    );

    await file.writeAsString('\uFEFF$content', encoding: utf8, flush: true);
    return file;
  }

  Future<File> exportPdf({
    required DateTime start,
    required DateTime end,
    required List<LedgerEntry> entries,
    required List<Account> accounts,
    required List<Category> categories,
  }) async {
    final document = pw.Document(
      title: 'Relatório financeiro',
      author: 'Meu App Financeiro',
      creator: 'Meu App Financeiro',
    );

    final accountNames = {
      for (final account in accounts) account.id: account.name,
    };
    final categoryNames = {
      for (final category in categories) category.id: category.name,
    };

    final incomeCents = _sum(
      entries.where((entry) => entry.isPaid && entry.type == 'income'),
    );
    final expenseCents = _sum(
      entries.where((entry) => entry.isPaid && entry.type == 'expense'),
    );
    final pendingIncomeCents = _sum(
      entries.where((entry) => !entry.isPaid && entry.type == 'income'),
    );
    final pendingExpenseCents = _sum(
      entries.where((entry) => !entry.isPaid && entry.type == 'expense'),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Meu App Financeiro',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${_formatDate(start)} a ${_formatDate(end)}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          pw.Text(
            'Relatório financeiro',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Período de ${_formatDate(start)} a ${_formatDate(end)}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 18),
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pdfSummaryCard('Receitas realizadas', incomeCents),
              _pdfSummaryCard('Despesas realizadas', expenseCents),
              _pdfSummaryCard('Saldo realizado', incomeCents - expenseCents),
              _pdfSummaryCard('A receber', pendingIncomeCents),
              _pdfSummaryCard('A pagar', pendingExpenseCents),
              _pdfCountCard('Movimentações', entries.length),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Movimentações',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (entries.isEmpty)
            pw.Text('Nenhuma movimentação encontrada no período.')
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'Data',
                'Descrição',
                'Tipo',
                'Valor',
                'Conta',
                'Categoria',
                'Status',
              ],
              data: entries
                  .map(
                    (entry) => [
                      _formatDate(entry.occurredAt),
                      entry.description,
                      _typeLabel(entry.type),
                      _formatCurrency(entry.amountCents),
                      accountNames[entry.accountId] ??
                          'Conta #${entry.accountId}',
                      entry.categoryId == null
                          ? '-'
                          : categoryNames[entry.categoryId] ??
                                'Categoria #${entry.categoryId}',
                      entry.isPaid ? _completedStatus(entry.type) : 'Pendente',
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellPadding: const pw.EdgeInsets.all(4),
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            ),
        ],
      ),
    );

    final file = await _createOutputFile(
      extension: 'pdf',
      start: start,
      end: end,
    );
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }

  pw.Widget _pdfSummaryCard(String label, int cents) {
    return pw.Container(
      width: 165,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 4),
          pw.Text(
            _formatCurrency(cents),
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfCountCard(String label, int count) {
    return pw.Container(
      width: 165,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 4),
          pw.Text(
            count.toString(),
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<File> _createOutputFile({
    required String extension,
    required DateTime start,
    required DateTime end,
  }) async {
    final documents = await getApplicationDocumentsDirectory();
    final outputDirectory = Directory(
      path.join(documents.path, 'Meu App Financeiro', 'Relatórios'),
    );

    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    final fileName =
        'relatorio_${DateFormat('yyyyMMdd').format(start)}_${DateFormat('yyyyMMdd').format(end)}.$extension';

    return File(path.join(outputDirectory.path, fileName));
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatCurrency(int cents) {
    final isNegative = cents < 0;
    final value = cents.abs() / 100;
    final parts = value.toStringAsFixed(2).split('.');
    final integerPart = parts.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    final result = 'R\$ $integerPart,${parts.last}';
    return isNegative ? '- $result' : result;
  }

  int _sum(Iterable<LedgerEntry> entries) {
    return entries.fold<int>(0, (sum, entry) => sum + entry.amountCents);
  }

  String _typeLabel(String type) {
    return switch (type) {
      'income' => 'Receita',
      'expense' => 'Despesa',
      'transfer' => 'Transferência',
      _ => type,
    };
  }

  String _completedStatus(String type) {
    return type == 'income' ? 'Recebido' : 'Pago';
  }

  String _csvRow(List<String> values) {
    return values.map(_escapeCsvValue).join(';');
  }

  String _escapeCsvValue(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
