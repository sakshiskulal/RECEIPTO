class WarrantyUtils {
  /// Parses YYYY-MM-DD string safely. Falls back to tryParse or current date.
  static DateTime _parseDate(String dateStr) {
    try {
      final clean = dateStr.trim();
      if (clean.isEmpty) return DateTime.now();
      final parts = clean.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }

  /// Formats a DateTime back to YYYY-MM-DD string.
  static String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Calculates expiry date automatically from purchaseDate, period, and unit.
  static String calculateExpiryDate(String purchaseDateStr, int period, String unit) {
    final purchaseDate = _parseDate(purchaseDateStr);
    final unitLower = unit.trim().toLowerCase();

    DateTime expiryDate;
    if (unitLower == 'days' || unitLower == 'day' || unitLower == 'd') {
      expiryDate = purchaseDate.add(Duration(days: period));
    } else if (unitLower == 'months' || unitLower == 'month' || unitLower == 'm') {
      int newYear = purchaseDate.year;
      int newMonth = purchaseDate.month + period;
      while (newMonth > 12) {
        newYear += 1;
        newMonth -= 12;
      }
      while (newMonth < 1) {
        newYear -= 1;
        newMonth += 12;
      }
      int newDay = purchaseDate.day;
      // Get the last day of the target month to prevent overflow
      final lastDayOfTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
      if (newDay > lastDayOfTargetMonth) {
        newDay = lastDayOfTargetMonth;
      }
      expiryDate = DateTime(newYear, newMonth, newDay);
    } else if (unitLower == 'years' || unitLower == 'year' || unitLower == 'y') {
      int newYear = purchaseDate.year + period;
      int newMonth = purchaseDate.month;
      int newDay = purchaseDate.day;
      final lastDayOfTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
      if (newDay > lastDayOfTargetMonth) {
        newDay = lastDayOfTargetMonth;
      }
      expiryDate = DateTime(newYear, newMonth, newDay);
    } else {
      // Fallback: default to months
      int newYear = purchaseDate.year;
      int newMonth = purchaseDate.month + period;
      while (newMonth > 12) {
        newYear += 1;
        newMonth -= 12;
      }
      int newDay = purchaseDate.day;
      final lastDayOfTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
      if (newDay > lastDayOfTargetMonth) {
        newDay = lastDayOfTargetMonth;
      }
      expiryDate = DateTime(newYear, newMonth, newDay);
    }

    return _formatDate(expiryDate);
  }

  /// Calculates remaining days between current date (today) and expiry date.
  static int calculateDaysRemaining(String expiryDateStr) {
    final expiry = _parseDate(expiryDateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryClean = DateTime(expiry.year, expiry.month, expiry.day);
    return expiryClean.difference(today).inDays;
  }

  /// Resolves the warranty status based on expiryDate.
  static String calculateStatus(String expiryDateStr) {
    final days = calculateDaysRemaining(expiryDateStr);
    if (days < 0) {
      return 'EXPIRED';
    } else if (days <= 30) {
      return 'EXPIRING_SOON';
    } else {
      return 'ACTIVE';
    }
  }

  /// Calculates total warranty period in days based on period and unit.
  static int calculateTotalDays(int period, String unit) {
    final unitLower = unit.trim().toLowerCase();
    if (unitLower.startsWith('y')) {
      return period * 365;
    } else if (unitLower.startsWith('m')) {
      return period * 30;
    } else {
      return period;
    }
  }
}
