import 'package:expense_tracker/core/date/year_month.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/dashboard/presentation/dashboard_screen.dart';
import 'package:expense_tracker/features/insights/presentation/insights_page.dart';
import 'package:expense_tracker/features/transactions/application/transaction_providers.dart';
import 'package:expense_tracker/features/transactions/data/transaction_repository.dart';
import 'package:expense_tracker/features/transactions/domain/expense_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  testWidgets('weekly spending bars remain visible with larger system text', (
    tester,
  ) async {
    final now = DateTime.now();
    final transactions = [
      _expense('week-one', DateTime(now.year, now.month, 1), 1200000),
      _expense('week-four', DateTime(now.year, now.month, 22), 1500000),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(body: InsightsPage(transactions: transactions)),
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Weekly spending trend'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('W1'), findsOneWidget);
    expect(find.text('W5'), findsOneWidget);
    final firstBar = tester.getSize(
      find.byKey(const ValueKey('weekly-spending-bar-0')),
    );
    final fourthBar = tester.getSize(
      find.byKey(const ValueKey('weekly-spending-bar-3')),
    );
    expect(firstBar.width, greaterThan(0));
    expect(firstBar.height, greaterThan(0));
    expect(fourthBar.width, greaterThan(0));
    expect(fourthBar.height, greaterThan(firstBar.height));
    expect(tester.takeException(), isNull);
  });

  testWidgets('selects historical months and shows final spending', (
    tester,
  ) async {
    final currentMonth = YearMonth.fromDate(DateTime.now());
    final selectedMonth = currentMonth.previous;
    YearMonth? changedMonth;
    final transactionDate = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      5,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: InsightsPage(
              transactions: [_expense('historical', transactionDate, 250000)],
              selectedMonth: selectedMonth,
              onMonthChanged: (month) => changedMonth = month,
            ),
          ),
        ),
      ),
    );

    expect(
      find.text(DateFormat('MMMM yyyy').format(selectedMonth.start)),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('previousInsightsMonthButton')));
    expect(changedMonth, selectedMonth.previous);

    await tester.tap(find.byKey(const Key('insightsMonthPickerButton')));
    await tester.pumpAndSettle();
    expect(find.text('Choose month'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    final finalSpending = find.text(
      'Final spending for ${DateFormat('MMMM').format(selectedMonth.start)}',
    );
    await tester.scrollUntilVisible(
      finalSpending,
      350,
      scrollable: find.byType(Scrollable),
    );
    expect(finalSpending, findsOneWidget);
    expect(find.text('Projected month-end spending'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens a routed Insights month without modifying providers', (
    tester,
  ) async {
    final repository = DemoTransactionRepository();
    addTearDown(repository.dispose);
    final selectedMonth = YearMonth.fromDate(DateTime.now()).previous;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: DashboardScreen(
            initialIndex: 1,
            initialInsightsMonth: selectedMonth,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text(DateFormat('MMMM yyyy').format(selectedMonth.start)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
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
