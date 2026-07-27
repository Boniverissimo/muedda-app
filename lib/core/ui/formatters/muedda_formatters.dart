import 'package:intl/intl.dart';

abstract final class MueddaFormatters {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  static final DateFormat _date = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final DateFormat _shortDate = DateFormat('dd MMM', 'pt_BR');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'pt_BR');

  static String currency(num value) => _currency.format(value);
  static String date(DateTime value) => _date.format(value);
  static String shortDate(DateTime value) => _shortDate.format(value);
  static String monthYear(DateTime value) => _capitalize(_monthYear.format(value));

  static String compactCurrency(num value) {
    final absolute = value.abs();
    if (absolute >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1).replaceAll('.', ',')} mi';
    }
    if (absolute >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(1).replaceAll('.', ',')} mil';
    }
    return currency(value);
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
