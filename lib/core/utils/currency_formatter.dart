class CurrencyFormatter {
  /// Formats an amount with the provided currency symbol, defaulting to '₹' (INR) if null or empty.
  static String format(double amount, {String? currency}) {
    final String symbol = (currency == null || currency.trim().isEmpty) ? '₹' : currency.trim();
    return '$symbol${amount.toStringAsFixed(2)}';
  }
  
  /// Formats an amount to a clean integer presentation if appropriate, or standard decimal.
  static String formatCompact(double amount, {String? currency}) {
    final String symbol = (currency == null || currency.trim().isEmpty) ? '₹' : currency.trim();
    if (amount == amount.toInt()) {
      return '$symbol${amount.toInt()}';
    }
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
