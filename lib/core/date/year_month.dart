class YearMonth implements Comparable<YearMonth> {
  const YearMonth(this.year, this.month)
    : assert(month >= DateTime.january && month <= DateTime.december);

  factory YearMonth.fromDate(DateTime date) => YearMonth(date.year, date.month);

  static YearMonth? tryParse(String? value) {
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value ?? '');
    if (match == null) return null;
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    if (year == null || month == null || month < 1 || month > 12) return null;
    return YearMonth(year, month);
  }

  final int year;
  final int month;

  DateTime get start => DateTime(year, month);
  DateTime get endExclusive => DateTime(year, month + 1);
  YearMonth get previous => YearMonth.fromDate(DateTime(year, month - 1));
  YearMonth get next => YearMonth.fromDate(DateTime(year, month + 1));
  String get routeValue => '$year-${month.toString().padLeft(2, '0')}';

  bool contains(DateTime date) => date.year == year && date.month == month;

  @override
  int compareTo(YearMonth other) {
    final yearComparison = year.compareTo(other.year);
    return yearComparison != 0 ? yearComparison : month.compareTo(other.month);
  }

  @override
  bool operator ==(Object other) =>
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}
