import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/features/dashboard/presentation/dashboard_screen.dart';
import 'package:expense_tracker/features/transactions/application/transaction_providers.dart';
import 'package:expense_tracker/features/transactions/data/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows dashboard and opens the transaction form', (tester) async {
    final repository = DemoTransactionRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
        ],
        child: const ExpenseTrackerApp(rootOverride: DashboardScreen()),
      ),
    );
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Monthly budget'), findsOneWidget);
    expect(find.text('Manage budget'), findsOneWidget);

    await tester.tap(find.text('Manage budget'));
    await tester.pumpAndSettle();
    expect(find.text('Manage monthly budget'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('budgetAmountField')), '75000');
    await tester.tap(find.byKey(const Key('saveBudgetButton')));
    await tester.pumpAndSettle();
    expect(find.textContaining('₹75,000'), findsWidgets);

    await tester.tap(find.byKey(const Key('addTransactionButton')));
    await tester.pumpAndSettle();

    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.byKey(const Key('titleField')), findsOneWidget);
    expect(find.byKey(const Key('amountField')), findsOneWidget);
    expect(find.byKey(const Key('saveTransactionButton')), findsOneWidget);
    expect(find.text('Need or Want?'), findsOneWidget);
    expect(find.text('Recurring Expense'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('recurringExpenseSwitch')));
    await tester.tap(find.byKey(const Key('recurringExpenseSwitch')));
    await tester.pumpAndSettle();
    expect(find.text('Repeat every'), findsOneWidget);
    expect(find.text('Monthly Type'), findsOneWidget);
    expect(find.text('12 months'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('increasePaymentsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('increasePaymentsButton')));
    await tester.pump();
    expect(find.text('13 months'), findsOneWidget);

    await tester.ensureVisible(find.text('Weekly'));
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();
    expect(find.text('Monthly Type'), findsNothing);
    expect(find.text('13 weeks'), findsOneWidget);

    await tester.ensureVisible(find.text('Income'));
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.text('Add Income'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Save Income'), findsOneWidget);
    expect(find.text('Need or Want?'), findsNothing);
    expect(find.text('Recurring Expense'), findsNothing);

    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('allTransactionsButton')), findsOneWidget);
    expect(find.text('Monthly salary'), findsOneWidget);
    expect(find.text('Weekly groceries'), findsOneWidget);

    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.text('Monthly salary'), findsOneWidget);
    expect(find.text('Weekly groceries'), findsNothing);

    await tester.tap(find.byKey(const Key('allTransactionsButton')));
    await tester.pumpAndSettle();
    expect(find.text('Weekly groceries'), findsOneWidget);
  });
}
