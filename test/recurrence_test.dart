import 'package:expense_tracker/features/transactions/domain/expense_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecurrenceConfig', () {
    test('uses calendar months and clamps to the last valid day', () {
      final recurrence = RecurrenceConfig.installments(
        frequency: RepeatFrequency.monthly,
        startDate: DateTime(2025, 1, 31),
        numberOfPayments: 2,
      );

      expect(recurrence.endDate, DateTime(2025, 2, 28));
      expect(recurrence.numberOfPayments, 2);
    });

    test('uses seven-day intervals for weekly installments', () {
      final recurrence = RecurrenceConfig.installments(
        frequency: RepeatFrequency.weekly,
        startDate: DateTime(2025, 1, 1),
        numberOfPayments: 3,
      );

      expect(recurrence.endDate, DateTime(2025, 1, 15));
    });

    test('ongoing recurrence has no end date or payment count', () {
      final recurrence = RecurrenceConfig.ongoing(
        frequency: RepeatFrequency.monthly,
        startDate: DateTime(2025, 1, 1),
      );

      expect(recurrence.endDate, isNull);
      expect(recurrence.numberOfPayments, isNull);
    });
  });
}
