import 'package:expense_tracker/core/date/year_month.dart';
import 'package:expense_tracker/features/transactions/domain/expense_transaction.dart';

class MonthlyInsightsSummary {
  MonthlyInsightsSummary._({
    required this.month,
    required this.isCurrentMonth,
    required this.transactions,
    required this.expenseItems,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.previousExpenseMinor,
    required this.categoryTotals,
    required this.weeklySpending,
    required this.memberSpending,
    required this.needSpendingMinor,
    required this.wantSpendingMinor,
    required this.projectedMonthEndMinor,
  });

  factory MonthlyInsightsSummary.calculate({
    required List<ExpenseTransaction> transactions,
    required YearMonth month,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final monthly = transactions
        .where((item) => month.contains(item.transactionDate))
        .toList();
    final expenses = monthly
        .where((item) => item.type == TransactionType.expense)
        .toList();
    final incomeMinor = monthly
        .where((item) => item.type == TransactionType.income)
        .fold<int>(0, (sum, item) => sum + item.amountMinor);
    final expenseMinor = expenses.fold<int>(
      0,
      (sum, item) => sum + item.amountMinor,
    );
    final previousExpenseMinor = transactions
        .where(
          (item) =>
              item.type == TransactionType.expense &&
              month.previous.contains(item.transactionDate),
        )
        .fold<int>(0, (sum, item) => sum + item.amountMinor);
    final categoryTotals = <String, int>{};
    final weeklySpending = List<int>.filled(5, 0);
    final memberSpending = <String, int>{};
    var needSpendingMinor = 0;
    var wantSpendingMinor = 0;
    for (final item in expenses) {
      categoryTotals.update(
        item.category,
        (value) => value + item.amountMinor,
        ifAbsent: () => item.amountMinor,
      );
      weeklySpending[((item.transactionDate.day - 1) ~/ 7).clamp(0, 4)] +=
          item.amountMinor;
      memberSpending.update(
        item.createdByName,
        (value) => value + item.amountMinor,
        ifAbsent: () => item.amountMinor,
      );
      if (item.priority == TransactionPriority.need) {
        needSpendingMinor += item.amountMinor;
      } else if (item.priority == TransactionPriority.want) {
        wantSpendingMinor += item.amountMinor;
      }
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final currentMonth = YearMonth.fromDate(today) == month;
    final projectedMonthEndMinor = currentMonth && expenseMinor > 0
        ? ((expenseMinor / today.day) *
                  month.endExclusive.subtract(const Duration(days: 1)).day)
              .round()
        : expenseMinor;

    return MonthlyInsightsSummary._(
      month: month,
      isCurrentMonth: currentMonth,
      transactions: List.unmodifiable(monthly),
      expenseItems: List.unmodifiable(expenses),
      incomeMinor: incomeMinor,
      expenseMinor: expenseMinor,
      previousExpenseMinor: previousExpenseMinor,
      categoryTotals: List.unmodifiable(sortedCategories),
      weeklySpending: List.unmodifiable(weeklySpending),
      memberSpending: Map.unmodifiable(memberSpending),
      needSpendingMinor: needSpendingMinor,
      wantSpendingMinor: wantSpendingMinor,
      projectedMonthEndMinor: projectedMonthEndMinor,
    );
  }

  final YearMonth month;
  final bool isCurrentMonth;
  final List<ExpenseTransaction> transactions;
  final List<ExpenseTransaction> expenseItems;
  final int incomeMinor;
  final int expenseMinor;
  final int previousExpenseMinor;
  final List<MapEntry<String, int>> categoryTotals;
  final List<int> weeklySpending;
  final Map<String, int> memberSpending;
  final int needSpendingMinor;
  final int wantSpendingMinor;
  final int projectedMonthEndMinor;
}
