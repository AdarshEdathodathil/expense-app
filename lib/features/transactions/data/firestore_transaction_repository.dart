import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/transactions/data/transaction_repository.dart';
import 'package:expense_tracker/features/transactions/domain/expense_transaction.dart';

/// Realtime shared-household implementation used after Firebase is configured.
/// Firestore's local cache supplies offline reads/writes and snapshots deliver
/// changes made by either household member.
class FirestoreTransactionRepository implements TransactionRepository {
  FirestoreTransactionRepository({
    required this.householdId,
    required this.currentUserId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String householdId;
  final String currentUserId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _transactions => _firestore
      .collection('households')
      .doc(householdId)
      .collection('transactions');

  @override
  Stream<List<ExpenseTransaction>> watchAll() {
    return _transactions
        .where('deletedAt', isNull: true)
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => _fromFirestore(document.id, document.data()))
              .toList(growable: false),
        );
  }

  @override
  Stream<SyncStatus> watchSyncStatus() {
    return _transactions
        .where('deletedAt', isNull: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          if (snapshot.metadata.hasPendingWrites) return SyncStatus.syncing;
          if (snapshot.metadata.isFromCache) return SyncStatus.offline;
          return SyncStatus.synced;
        });
  }

  @override
  Future<void> add(ExpenseTransaction transaction) {
    if (transaction.createdBy != currentUserId) {
      throw StateError(
        'A transaction can only be created as the signed-in user.',
      );
    }
    return _transactions
        .doc(transaction.id)
        .set(_toFirestore(transaction, isNew: true));
  }

  @override
  Future<void> update(ExpenseTransaction transaction) {
    if (transaction.householdId != householdId) {
      throw StateError('Transaction belongs to another household.');
    }
    return _transactions.doc(transaction.id).update(_toFirestore(transaction));
  }

  Map<String, dynamic> _toFirestore(
    ExpenseTransaction transaction, {
    bool isNew = false,
  }) {
    return {
      'householdId': householdId,
      'type': transaction.type.name,
      'amountMinor': transaction.amountMinor,
      'currency': transaction.currency,
      'category': transaction.category,
      'note': transaction.note,
      'transactionDate': Timestamp.fromDate(
        transaction.transactionDate.toUtc(),
      ),
      'createdBy': transaction.createdBy,
      'createdByName': transaction.createdByName,
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'deletedAt': null,
      'needOrWant': transaction.priority?.name,
      'isRecurring': transaction.recurrence != null,
      'repeatFrequency': transaction.recurrence?.frequency.name,
      'monthlyType': transaction.recurrence?.mode.name,
      'numberOfPayments': transaction.recurrence?.numberOfPayments,
      'recurrenceStartDate': transaction.recurrence == null
          ? null
          : Timestamp.fromDate(transaction.recurrence!.startDate.toUtc()),
      'recurrenceEndDate': transaction.recurrence?.endDate == null
          ? null
          : Timestamp.fromDate(transaction.recurrence!.endDate!.toUtc()),
      'recurrenceParentId': null,
      'occurrenceDate': null,
    };
  }

  @override
  Future<void> delete(String transactionId) {
    return _transactions.doc(transactionId).update({
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  ExpenseTransaction _fromFirestore(String id, Map<String, dynamic> data) {
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
    final isRecurring = data['isRecurring'] as bool? ?? false;
    final recurrenceMode = data['monthlyType'] == 'ongoing'
        ? RecurrenceMode.ongoing
        : RecurrenceMode.installments;
    final frequency = data['repeatFrequency'] == 'weekly'
        ? RepeatFrequency.weekly
        : RepeatFrequency.monthly;
    final recurrenceStart = (data['recurrenceStartDate'] as Timestamp?)
        ?.toDate();
    final recurrenceEnd = (data['recurrenceEndDate'] as Timestamp?)?.toDate();
    final priority = switch (data['needOrWant']) {
      'need' => TransactionPriority.need,
      'want' => TransactionPriority.want,
      _ => null,
    };

    return ExpenseTransaction(
      id: id,
      householdId: householdId,
      type: data['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amountMinor: data['amountMinor'] as int,
      currency: data['currency'] as String,
      category: data['category'] as String,
      note: data['note'] as String? ?? '',
      transactionDate: (data['transactionDate'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String,
      createdByName: data['createdByName'] as String,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? createdAt ?? DateTime.now(),
      priority: priority,
      recurrence: isRecurring && recurrenceStart != null
          ? RecurrenceConfig(
              frequency: frequency,
              mode: recurrenceMode,
              numberOfPayments: data['numberOfPayments'] as int?,
              startDate: recurrenceStart,
              endDate: recurrenceEnd,
            )
          : null,
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  void dispose() {}
}
