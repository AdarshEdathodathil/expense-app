import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/features/dashboard/presentation/dashboard_screen.dart';
import 'package:expense_tracker/features/transactions/application/transaction_providers.dart';
import 'package:expense_tracker/features/transactions/data/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('bottom navigation exposes accessible labels', (tester) async {
    final repository = DemoTransactionRepository();
    addTearDown(repository.dispose);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
        ],
        child: const ExpenseTrackerApp(rootOverride: DashboardScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.bySemanticsLabel(RegExp('Go to Home')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Go to Transactions')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Go to Add')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Go to Insights')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Go to Settings')), findsOneWidget);
    semantics.dispose();
  });
}
