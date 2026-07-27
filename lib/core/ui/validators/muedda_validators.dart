abstract final class MueddaValidators {
  static String? requiredText(String? value, {String field = 'Campo'}) {
    if (value == null || value.trim().isEmpty) return '$field é obrigatório';
    return null;
  }

  static String? positiveMoney(String? value, {String field = 'Valor'}) {
    if (value == null || value.trim().isEmpty) return '$field é obrigatório';
    final normalized = value
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) return 'Informe um valor maior que zero';
    return null;
  }

  static String? dayOfMonth(String? value) {
    final day = int.tryParse(value ?? '');
    if (day == null || day < 1 || day > 31) return 'Informe um dia entre 1 e 31';
    return null;
  }
}
