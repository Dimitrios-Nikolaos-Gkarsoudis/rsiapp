const Map<String, String> _currencySymbols = {
  'EUR': '€',
  'GBP': '£',
  'USD': r'$',
};

const List<String> _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats a price, dropping decimals for whole amounts: €32, €27.20.
String formatPrice(double amount, String currency) {
  final isWhole = amount == amount.roundToDouble();
  final number = amount.toStringAsFixed(isWhole ? 0 : 2);
  final symbol = _currencySymbols[currency];

  return symbol == null ? '$number $currency' : '$symbol$number';
}

/// Formats a date as "31 Oct 2026".
String formatShortDate(DateTime date) {
  return '${date.day} ${_monthAbbreviations[date.month - 1]} ${date.year}';
}

/// Formats a date and time as "3 Nov 2025, 18:40".
String formatDateTime(DateTime dateTime) {
  final hours = dateTime.hour.toString().padLeft(2, '0');
  final minutes = dateTime.minute.toString().padLeft(2, '0');

  return '${formatShortDate(dateTime)}, $hours:$minutes';
}
