enum TransactionType { income, expense }

enum TransactionPriority { need, want }

enum RepeatFrequency { monthly, weekly }

enum RecurrenceMode { installments, ongoing }

class RecurrenceConfig {
  const RecurrenceConfig({
    required this.frequency,
    required this.mode,
    required this.startDate,
    this.numberOfPayments,
    this.endDate,
  });

  factory RecurrenceConfig.installments({
    required RepeatFrequency frequency,
    required DateTime startDate,
    required int numberOfPayments,
  }) {
    assert(numberOfPayments >= 1);
    return RecurrenceConfig(
      frequency: frequency,
      mode: RecurrenceMode.installments,
      startDate: startDate,
      numberOfPayments: numberOfPayments,
      endDate: _installmentEndDate(startDate, frequency, numberOfPayments),
    );
  }

  factory RecurrenceConfig.ongoing({
    required RepeatFrequency frequency,
    required DateTime startDate,
  }) => RecurrenceConfig(
    frequency: frequency,
    mode: RecurrenceMode.ongoing,
    startDate: startDate,
  );

  final RepeatFrequency frequency;
  final RecurrenceMode mode;
  final int? numberOfPayments;
  final DateTime startDate;
  final DateTime? endDate;

  static DateTime _installmentEndDate(
    DateTime start,
    RepeatFrequency frequency,
    int paymentCount,
  ) {
    final intervals = paymentCount - 1;
    if (frequency == RepeatFrequency.weekly) {
      return start.add(Duration(days: intervals * 7));
    }

    final targetMonth = start.month - 1 + intervals;
    final year = start.year + targetMonth ~/ 12;
    final month = targetMonth % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = start.day.clamp(1, lastDay);
    return DateTime(
      year,
      month,
      day,
      start.hour,
      start.minute,
      start.second,
      start.millisecond,
      start.microsecond,
    );
  }
}

class ExpenseTransaction {
  const ExpenseTransaction({
    required this.id,
    required this.householdId,
    required this.type,
    required this.amountMinor,
    required this.currency,
    required this.category,
    required this.note,
    required this.transactionDate,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.priority,
    this.recurrence,
    this.deletedAt,
  });

  final String id;
  final String householdId;
  final TransactionType type;
  final int amountMinor;
  final String currency;
  final String category;
  final String note;
  final DateTime transactionDate;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TransactionPriority? priority;
  final RecurrenceConfig? recurrence;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
}
