/// Utility class for formatting currency in Indian number system
/// Follows Indian comma standard: 1,00,000 (1 lakh), 10,00,000 (10 lakhs), etc.
class IndianCurrencyFormatter {
  /// Format amount as Indian currency string
  /// Examples:
  /// - 100 → ₹100
  /// - 1000 → ₹1,000
  /// - 10000 → ₹10,000
  /// - 100000 → ₹1,00,000
  /// - 1000000 → ₹10,00,000
  /// - 10000000 → ₹1,00,00,000
  static String format(double amount, {bool showSymbol = true}) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    
    // Round to 2 decimal places
    final roundedAmount = (absAmount * 100).round() / 100;
    
    // Split into integer and decimal parts
    final parts = roundedAmount.toString().split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';
    
    // Format integer part with Indian comma system
    final formatted = _formatIndianNumber(integerPart);
    
    // Build final string
    final buffer = StringBuffer();
    if (isNegative) buffer.write('-');
    if (showSymbol) buffer.write('₹');
    buffer.write(formatted);
    
    // Add decimal part only if non-zero
    if (decimalPart.isNotEmpty && int.parse(decimalPart.padRight(2, '0')) > 0) {
      buffer.write('.');
      buffer.write(decimalPart.padRight(2, '0').substring(0, 2));
    }
    
    return buffer.toString();
  }
  
  /// Format integer part with Indian comma system
  /// Indian system: XX,XX,XXX (commas after every 2 digits from right, except the first 3)
  static String _formatIndianNumber(String number) {
    if (number.length <= 3) return number;
    
    final buffer = StringBuffer();
    int count = 0;
    
    // Reverse iterate through the number
    for (int i = number.length - 1; i >= 0; i--) {
      if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) {
        buffer.write(',');
      }
      buffer.write(number[i]);
      count++;
    }
    
    // Reverse the result
    return buffer.toString().split('').reversed.join('');
  }
  
  /// Format amount for display (removes trailing zeros)
  static String formatCompact(double amount, {bool showSymbol = true}) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    
    String formatted;
    if (absAmount >= 10000000) {
      // Crores
      formatted = '${(absAmount / 10000000).toStringAsFixed(2)} Cr';
    } else if (absAmount >= 100000) {
      // Lakhs
      formatted = '${(absAmount / 100000).toStringAsFixed(2)} L';
    } else if (absAmount >= 1000) {
      // Thousands
      formatted = '${(absAmount / 1000).toStringAsFixed(2)} K';
    } else {
      formatted = absAmount.toStringAsFixed(0);
    }
    
    final buffer = StringBuffer();
    if (isNegative) buffer.write('-');
    if (showSymbol) buffer.write('₹');
    buffer.write(formatted);
    
    return buffer.toString();
  }
  
  /// Parse Indian formatted currency string to double
  static double parse(String formattedAmount) {
    // Remove currency symbol and commas
    final cleaned = formattedAmount
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
}
