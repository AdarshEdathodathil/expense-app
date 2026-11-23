import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/features/dashboard/presentation/dashboard_screen.dart';
import 'package:expense_tracker/features/transactions/application/transaction_providers.dart';
import 'package:expense_tracker/features/transactions/data/transaction_repository.dart';
import 'package:expense_tracker/features/transactions/domain/expense_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'home shows five latest transactions with See all at the bottom',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = DemoTransactionRepository();
      addTearDown(repository.dispose);
      final now = DateTime.now();
      for (var index = 1; index <= 3; index++) {
        await repository.add(
          ExpenseTransaction(
            id: 'new-$index',
            householdId: 'demo-household',
            type: TransactionType.expense,
            amountMinor: index * 10000,
            currency: 'INR',
            category: 'Test $index',
            note: '',
            transactionDate: now.add(Duration(days: index)),
            createdBy: 'demo-user',
            createdByName: 'You',
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(repository),
          ],
          child: const ExpenseTrackerApp(rootOverride: DashboardScreen()),
        ),
      );
    await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      final transactionTiles = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'homeTransaction-',
            ),
      );
      final seeAll = find.byKey(const Key('homeSeeAllTransactionsButton'));

      expect(transactionTiles, findsNWidgets(5));
      expect(seeAll, findsOneWidget);
      expect(tester.widget(seeAll), isA<FilledButton>());
      expect(
        tester.getTopLeft(seeAll).dy,
        greaterThan(tester.getBottomLeft(transactionTiles.last).dy),
      );
    },
  );
}
