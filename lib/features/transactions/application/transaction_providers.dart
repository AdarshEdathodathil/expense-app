import 'package:expense_tracker/features/households/application/household_session.dart';
import 'package:expense_tracker/features/transactions/data/firestore_transaction_repository.dart';
import 'package:expense_tracker/features/transactions/data/transaction_repository.dart';
import 'package:expense_tracker/features/transactions/domain/expense_transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final session = ref.watch(householdSessionProvider);
  if (session == null) {
    throw StateError('A household session is required for transactions.');
  }
  return FirestoreTransactionRepository(
    householdId: session.householdId,
    currentUserId: session.userId,
  );
});

final transactionsProvider = StreamProvider<List<ExpenseTransaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAll();
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(transactionRepositoryProvider).watchSyncStatus();
});
