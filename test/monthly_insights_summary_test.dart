import 'package:expense_tracker/core/date/year_month.dart';
import 'package:expense_tracker/features/insights/domain/monthly_insights_summary.dart';
import 'package:expense_tracker/features/transactions/domain/expense_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('YearMonth crosses year boundaries and parses route values', () {
    const january = YearMonth(2026, DateTime.january);

    expect(january.previous, const YearMonth(2025, DateTime.december));
    expect(january.previous.next, january);
    expect(YearMonth.tryParse('2026-01'), january);
    expect(YearMonth.tryParse('2026-13'), isNull);
  });

  test('calculates a historical month and its previous comparison', () {
    const selected = YearMonth(2026, DateTime.october);
    final transactions = [
      _expense('september', DateTime(2026, 9, 30), 30000),
      _expense('week-one', DateTime(2026, 10, 1), 120000),
      _expense('week-five', DateTime(2026, 10, 31), 80000),
      _income('salary', DateTime(2026, 10, 1), 500000),
      _expense('november', DateTime(2026, 11, 1), 999999),
    ];

    final summary = MonthlyInsightsSummary.calculate(
      transactions: transactions,
      month: selected,
      now: DateTime(2026, 11, 23),
    );

    expect(summary.isCurrentMonth, isFalse);
    expect(summary.expenseMinor, 200000);
    expect(summary.incomeMinor, 500000);
    expect(summary.previousExpenseMinor, 30000);
    expect(summary.weeklySpending, [120000, 0, 0, 0, 80000]);
    expect(summary.projectedMonthEndMinor, summary.expenseMinor);
  });
}

ExpenseTransaction _expense(String id, DateTime date, int amountMinor) {
  return ExpenseTransaction(
    id: id,
    householdId: 'household',
    type: TransactionType.expense,
    amountMinor: amountMinor,
    currency: 'INR',
    category: 'Food',
    note: '',
    transactionDate: date,
    createdBy: 'user',
    createdByName: 'Member',
    createdAt: date,
    updatedAt: date,
    priority: TransactionPriority.need,
  );
}

ExpenseTransaction _income(String id, DateTime date, int amountMinor) {
  return ExpenseTransaction(
    id: id,
    householdId: 'household',
    type: TransactionType.income,
    amountMinor: amountMinor,
    currency: 'INR',
    category: 'Salary',
    note: '',
    transactionDate: date,
    createdBy: 'user',
    createdByName: 'Member',
    createdAt: date,
    updatedAt: date,
  );
}
