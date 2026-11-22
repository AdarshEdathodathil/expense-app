import 'dart:async';

import 'package:expense_tracker/features/transactions/domain/expense_transaction.dart';

enum SyncStatus { synced, syncing, offline }

abstract interface class TransactionRepository {
  Stream<List<ExpenseTransaction>> watchAll();
  Stream<SyncStatus> watchSyncStatus();
  Future<void> add(ExpenseTransaction transaction);
  Future<void> update(ExpenseTransaction transaction);
  Future<void> delete(String transactionId);
  void dispose();
}

/// In-memory repository retained for isolated widget tests only.
class DemoTransactionRepository implements TransactionRepository {
  DemoTransactionRepository() {
    final now = DateTime.now();
    _items.addAll([
      ExpenseTransaction(
        id: 'sample-grocery',
        householdId: 'demo-household',
        type: TransactionType.expense,
        amountMinor: 284050,
        currency: 'INR',
        category: 'Groceries',
        note: 'Weekly groceries',
        transactionDate: now.subtract(const Duration(days: 1)),
        createdBy: 'demo-user-2',
        createdByName: 'Wife',
        createdAt: now,
        updatedAt: now,
      ),
      ExpenseTransaction(
        id: 'sample-salary',
        householdId: 'demo-household',
        type: TransactionType.income,
        amountMinor: 8500000,
        currency: 'INR',
        category: 'Salary',
        note: 'Monthly salary',
        transactionDate: DateTime(now.year, now.month, 1),
        createdBy: 'demo-user-1',
        createdByName: 'You',
        createdAt: now,
        updatedAt: now,
      ),
      ExpenseTransaction(
        id: 'sample-utilities',
        householdId: 'demo-household',
        type: TransactionType.expense,
        amountMinor: 367500,
        currency: 'INR',
        category: 'Utilities',
        note: 'Electricity and internet',
        transactionDate: now.subtract(const Duration(days: 3)),
        createdBy: 'demo-user-1',
        createdByName: 'You',
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  }

  final List<ExpenseTransaction> _items = [];
  final _controller = StreamController<List<ExpenseTransaction>>.broadcast();

  @override
  Stream<List<ExpenseTransaction>> watchAll() async* {
    yield _sortedItems();
    yield* _controller.stream;
  }

  @override
  Stream<SyncStatus> watchSyncStatus() async* {
    yield SyncStatus.synced;
    yield* _controller.stream.map((_) => SyncStatus.synced);
  }

  @override
  Future<void> add(ExpenseTransaction transaction) async {
    _items.add(transaction);
    _controller.add(_sortedItems());
  }

  @override
  Future<void> delete(String transactionId) async {
    final index = _items.indexWhere((item) => item.id == transactionId);
    if (index == -1) return;
    final current = _items[index];
    _items[index] = ExpenseTransaction(
      id: current.id,
      householdId: current.householdId,
      type: current.type,
      amountMinor: current.amountMinor,
      currency: current.currency,
      category: current.category,
      note: current.note,
      transactionDate: current.transactionDate,
      createdBy: current.createdBy,
      createdByName: current.createdByName,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      priority: current.priority,
      recurrence: current.recurrence,
      deletedAt: DateTime.now(),
    );
    _controller.add(_sortedItems());
  }

  @override
  Future<void> update(ExpenseTransaction transaction) async {
    final index = _items.indexWhere((item) => item.id == transaction.id);
    if (index == -1) throw StateError('Transaction not found.');
    _items[index] = transaction;
    _controller.add(_sortedItems());
  }

  List<ExpenseTransaction> _sortedItems() {
    final result = _items.where((item) => !item.isDeleted).toList();
    result.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return List.unmodifiable(result);
  }

  @override
  void dispose() => _controller.close();
}
