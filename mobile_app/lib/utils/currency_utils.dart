import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _formatter = NumberFormat.currency(
    symbol: 'Rs. ',
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormatter = NumberFormat.compactCurrency(
    symbol: 'Rs. ',
    decimalDigits: 1,
  );

  /// Formats a double amount into a currency string (e.g., Rs. 10,250.00)
  static String format(double amount) {
    return _formatter.format(amount);
  }

  /// Formats a double amount into a compact currency string (e.g., Rs. 1.2M)
  static String formatCompact(double amount) {
    return _compactFormatter.format(amount);
  }
  
  /// Returns only the symbol
  static String get symbol => 'Rs. ';
}
