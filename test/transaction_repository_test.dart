import 'package:expense_tracker/features/transactions/data/transaction_repository.dart';
import 'package:expense_tracker/features/transactions/domain/expense_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo repository updates and soft-deletes transactions', () async {
    final repository = DemoTransactionRepository();
    addTearDown(repository.dispose);
    final original = (await repository.watchAll().first).first;
    final updated = ExpenseTransaction(
      id: original.id,
      householdId: original.householdId,
      type: original.type,
      amountMinor: original.amountMinor + 100,
      currency: original.currency,
      category: original.category,
      note: original.note,
      transactionDate: original.transactionDate,
      createdBy: original.createdBy,
      createdByName: original.createdByName,
      createdAt: original.createdAt,
      updatedAt: DateTime.now(),
      priority: original.priority,
      recurrence: original.recurrence,
    );

    await repository.update(updated);
    expect(
      (await repository.watchAll().first).first.amountMinor,
      updated.amountMinor,
    );
    await repository.delete(updated.id);
    expect(
      (await repository.watchAll().first).any((item) => item.id == updated.id),
      isFalse,
    );
  });
}
