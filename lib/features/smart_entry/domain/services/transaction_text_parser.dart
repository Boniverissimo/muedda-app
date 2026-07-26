import '../models/parsed_transaction.dart';

class TransactionTextParser {
  const TransactionTextParser();

  ParsedTransaction parse(String input, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final normalized = _normalize(input);
    final amountCents = _extractAmountCents(normalized);
    final type = _detectType(normalized);
    final occurredAt = _extractDate(normalized, reference);
    final category = _suggestCategory(normalized, type);
    final description = _extractDescription(input, normalized, amountCents);

    var confidence = 0.15;
    if (amountCents != null) confidence += 0.4;
    if (description != null && description.isNotEmpty) confidence += 0.25;
    if (_containsTypeKeyword(normalized)) confidence += 0.1;
    if (category != null) confidence += 0.1;

    return ParsedTransaction(
      originalText: input.trim(),
      type: type,
      description: description,
      amountCents: amountCents,
      occurredAt: occurredAt,
      suggestedCategoryName: category,
      confidence: confidence.clamp(0, 1),
    );
  }

  int? _extractAmountCents(String text) {
    final currencyMatches = RegExp(
      r'(?:r\$\s*)?(\d{1,3}(?:\.\d{3})*(?:,\d{1,2})|\d+(?:[\.,]\d{1,2})?)\s*(?:reais|real)?',
      caseSensitive: false,
    ).allMatches(text).toList();

    if (currencyMatches.isEmpty) return null;

    final candidates = <double>[];
    for (final match in currencyMatches) {
      final raw = match.group(1);
      if (raw == null) continue;
      final value = _parseBrazilianNumber(raw);
      if (value != null && value > 0) candidates.add(value);
    }

    if (candidates.isEmpty) return null;
    final selected = candidates.reduce((a, b) => a >= b ? a : b);
    return (selected * 100).round();
  }

  double? _parseBrazilianNumber(String raw) {
    var value = raw.trim();
    if (value.contains(',')) {
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else {
      final parts = value.split('.');
      if (parts.length > 2) {
        value = parts.join();
      }
    }
    return double.tryParse(value);
  }

  String _detectType(String text) {
    if (_containsAny(text, const [
      'transferi',
      'transferencia',
      'transferência',
      'enviei para',
      'mandei para',
    ])) {
      return 'transfer';
    }

    if (_containsAny(text, const [
      'recebi',
      'ganhei',
      'salario',
      'salário',
      'renda',
      'reembolso',
      'entrada',
      'vendi',
    ])) {
      return 'income';
    }

    if (_containsAny(text, const [
      'cartao',
      'cartão',
      'credito',
      'crédito',
      'fatura',
    ])) {
      return 'card';
    }

    return 'expense';
  }

  bool _containsTypeKeyword(String text) {
    return _containsAny(text, const [
      'paguei',
      'gastei',
      'comprei',
      'recebi',
      'ganhei',
      'transferi',
      'cartao',
      'cartão',
    ]);
  }

  DateTime _extractDate(String text, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (text.contains('anteontem')) {
      return today.subtract(const Duration(days: 2));
    }
    if (text.contains('ontem')) {
      return today.subtract(const Duration(days: 1));
    }
    if (text.contains('amanha') || text.contains('amanhã')) {
      return today.add(const Duration(days: 1));
    }

    final fullDate = RegExp(
      r'\b(\d{1,2})/(\d{1,2})/(\d{2,4})\b',
    ).firstMatch(text);
    if (fullDate != null) {
      final day = int.parse(fullDate.group(1)!);
      final month = int.parse(fullDate.group(2)!);
      var year = int.parse(fullDate.group(3)!);
      if (year < 100) year += 2000;
      final parsed = _safeDate(year, month, day);
      if (parsed != null) return parsed;
    }

    final shortDate = RegExp(r'\b(\d{1,2})/(\d{1,2})\b').firstMatch(text);
    if (shortDate != null) {
      final parsed = _safeDate(
        now.year,
        int.parse(shortDate.group(2)!),
        int.parse(shortDate.group(1)!),
      );
      if (parsed != null) return parsed;
    }

    final dayOnly = RegExp(r'\bdia\s+(\d{1,2})\b').firstMatch(text);
    if (dayOnly != null) {
      final parsed = _safeDate(
        now.year,
        now.month,
        int.parse(dayOnly.group(1)!),
      );
      if (parsed != null) return parsed;
    }

    return today;
  }

  DateTime? _safeDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final value = DateTime(year, month, day);
    if (value.year != year || value.month != month || value.day != day) {
      return null;
    }
    return value;
  }

  String? _suggestCategory(String text, String type) {
    if (type == 'income') {
      if (_containsAny(text, const ['salario', 'salário', 'pagamento'])) {
        return 'Salário';
      }
      if (_containsAny(text, const ['venda', 'vendi'])) return 'Vendas';
      if (text.contains('reembolso')) return 'Reembolso';
      return 'Outras receitas';
    }

    const rules = <String, List<String>>{
      'Mercado': [
        'mercado',
        'supermercado',
        'assai',
        'assaí',
        'atacadao',
        'atacadão',
        'carrefour',
      ],
      'Alimentação': [
        'ifood',
        'restaurante',
        'padaria',
        'lanche',
        'pizza',
        'comida',
      ],
      'Transporte': [
        'uber',
        '99',
        'onibus',
        'ônibus',
        'metro',
        'metrô',
        'estacionamento',
        'pedagio',
        'pedágio',
      ],
      'Combustível': [
        'gasolina',
        'etanol',
        'diesel',
        'combustivel',
        'combustível',
        'posto',
        'shell',
        'ipiranga',
      ],
      'Moradia': ['aluguel', 'condominio', 'condomínio'],
      'Contas': [
        'internet',
        'telefone',
        'energia',
        'luz',
        'agua',
        'água',
        'gas',
        'gás',
      ],
      'Saúde': [
        'farmacia',
        'farmácia',
        'medico',
        'médico',
        'consulta',
        'remedio',
        'remédio',
      ],
      'Assinaturas': [
        'spotify',
        'netflix',
        'amazon prime',
        'youtube premium',
        'assinatura',
      ],
      'Compras': ['mercado livre', 'shopee', 'amazon', 'loja'],
      'Educação': ['curso', 'faculdade', 'escola', 'livro'],
      'Lazer': ['cinema', 'show', 'viagem', 'passeio'],
    };

    for (final entry in rules.entries) {
      if (_containsAny(text, entry.value)) return entry.key;
    }
    return null;
  }

  String? _extractDescription(
    String original,
    String normalized,
    int? amountCents,
  ) {
    var result = original.trim();
    result = result.replaceAll(
      RegExp(r'\b(hoje|ontem|anteontem|amanh[ãa])\b', caseSensitive: false),
      '',
    );
    result = result.replaceAll(
      RegExp(
        r'\b(?:dia\s+)?\d{1,2}/\d{1,2}(?:/\d{2,4})?\b',
        caseSensitive: false,
      ),
      '',
    );
    result = result.replaceAll(
      RegExp(
        r'(?:r\$\s*)?\d{1,3}(?:\.\d{3})*(?:,\d{1,2})|(?:r\$\s*)?\d+(?:[\.,]\d{1,2})?\s*(?:reais|real)?',
        caseSensitive: false,
      ),
      '',
    );
    result = result.replaceAll(
      RegExp(
        r'\b(paguei|gastei|comprei|recebi|ganhei|transferi|despesa|receita|valor|de|por|com|no|na|em|para|do|da)\b',
        caseSensitive: false,
      ),
      ' ',
    );
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    result = result.replaceAll(RegExp(r'^[,;:\-]+|[,;:\-]+$'), '').trim();

    if (result.isEmpty) {
      final category = _suggestCategory(normalized, _detectType(normalized));
      return category;
    }

    return result[0].toUpperCase() + result.substring(1);
  }

  bool _containsAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }

  String _normalize(String value) {
    return value.toLowerCase().trim();
  }
}
