const { onSchedule } = require('firebase-functions/v2/scheduler');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();
setGlobalOptions({ region: 'asia-south1', maxInstances: 1 });

const db = admin.firestore();
const Timestamp = admin.firestore.Timestamp;

function nextDate(start, frequency, offset) {
  if (frequency === 'weekly') {
    return new Date(start.getTime() + offset * 7 * 86400000);
  }
  const result = new Date(start);
  result.setMonth(result.getMonth() + offset);
  if (result.getDate() !== start.getDate()) result.setDate(0);
  return result;
}

exports.generateRecurringTransactions = onSchedule('every day 02:15', async () => {
  const snapshot = await db.collectionGroup('transactions')
    .where('isRecurring', '==', true)
    .where('deletedAt', '==', null)
    .get();
  const now = new Date();
  const writes = [];

  for (const source of snapshot.docs) {
    const data = source.data();
    const start = data.recurrenceStartDate?.toDate();
    if (!start || start > now) continue;
    const frequency = data.repeatFrequency === 'weekly' ? 'weekly' : 'monthly';
    const intervalMs = frequency === 'weekly' ? 7 * 86400000 : 28 * 86400000;
    const maxPayments = data.monthlyType === 'installments' ? (data.numberOfPayments || 1) : 240;
    const end = data.recurrenceEndDate?.toDate();
    const parent = source.ref.parent.parent;
    if (!parent) continue;

    for (let index = 1; index <= maxPayments; index++) {
      const occurrence = nextDate(start, frequency, index);
      if (occurrence > now || (end && occurrence > end)) break;
      const dateKey = occurrence.toISOString().slice(0, 10);
      const target = parent.collection('transactions').doc(`${source.id}_${dateKey}`);
      const existing = await target.get();
      if (existing.exists) continue;
      writes.push(target.set({
        ...data,
        transactionDate: Timestamp.fromDate(occurrence),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        isRecurring: false,
        recurrenceParentId: source.id,
        occurrenceDate: dateKey,
        numberOfPayments: null,
        recurrenceStartDate: null,
        recurrenceEndDate: null,
      }));
    }
  }
  await Promise.all(writes);
});
